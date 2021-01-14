/*
    Copyright 2021 Empty Apple Dev <bigemptyapple@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '../external/UniswapV2OracleLibrary.sol';
import '../external/UniswapV2Library.sol';
import "../external/Require.sol";
import "../external/Decimal.sol";
import "./IOracle.sol";
import "./IUSDC.sol";
import "../Constants.sol";

import "./PoolGetters.sol";
import "./PoolSetters.sol";

contract Oracle is IOracle,PoolSetters {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    bytes32 private constant FILE = "Oracle";
    address private constant UNISWAP_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address internal _dao;
    address internal _dollar;

    bool internal _initialized;
    IUniswapV2Pair internal _pair;
    IUniswapV2Pair internal _pair2;
    uint256 internal _index;
    uint256 internal _index3;
    uint256 internal _cumulative;
    uint256 internal _cumulative2;
    uint32 internal _timestamp;
    uint32 internal _timestamp2;

    uint256 internal _reserve;

    uint256 internal _ethPrice;
    // uint256 priceCumulative;
    // uint256 priceCumulative3;

    struct PriceInfo {
    uint32 timeElapsed;
    uint32 timeElapsed2;
    uint256 priceCumulative;
    uint256 priceCumulative3;
    }

    constructor (address dollar) public {
        _dao = msg.sender;
        _dollar = dollar;
        _state.provider.dao = IDAO(msg.sender);
    }

    function setup() public onlyDao {
        _pair = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).createPair(_dollar, usdc()));
        _pair2 = IUniswapV2Pair(IUniswapV2Factory(UNISWAP_FACTORY).getPair(weth(), usdc()));

        (address token0, address token1) = (_pair.token0(), _pair.token1());
        _index = _dollar == token0 ? 0 : 1;

        (address token3, address token4) = (_pair2.token0(), _pair2.token1());
        _index3 = weth() == token3 ? 0 : 1;

        Require.that(
            _index == 0 || _dollar == token1,
            FILE,
            "Døllar not found"
        );
    }

    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture() public onlyDao returns (Decimal.D256 memory, bool) {
        if (_initialized) {
            return updateOracle();
        } else {
            initializeOracle();
            return (Decimal.one(), false);
        }
    }

    function initializeOracle() private {
        IUniswapV2Pair pair = _pair;
        IUniswapV2Pair pair2 = _pair2;
        uint256 priceCumulative = _index == 0 ?
            pair.price0CumulativeLast() :
            pair.price1CumulativeLast();
        uint256 priceCumulative2 = _index == 0 ?
            pair2.price0CumulativeLast() :
            pair2.price1CumulativeLast();

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        (uint112 reserve3, uint112 reserve4, uint32 blockTimestampLast2) = pair2.getReserves();
        if(reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            _cumulative = priceCumulative;
            _cumulative2 = priceCumulative2;
            _timestamp = blockTimestampLast;
            _timestamp2 = blockTimestampLast2;
            _initialized = true;
            _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        }
    }

    function updateOracle() private returns (Decimal.D256 memory, bool) {
        Decimal.D256 memory price = updatePrice();
        uint256 lastReserve = updateReserve();
        bool isBlacklisted = IUSDC(usdc()).isBlacklisted(address(_pair));

        bool valid = true;
        if (lastReserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (_reserve < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        if (isBlacklisted) {
            valid = false;
        }

        return (price, valid);
    }

    function updatePrice() private returns (Decimal.D256 memory) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        (uint256 price3Cumulative, uint256 price4Cumulative, uint32 blockTimestamp2) =
        UniswapV2OracleLibrary.currentCumulativePrices(address(_pair2));

        PriceInfo memory pricesinfo;

        pricesinfo.timeElapsed = blockTimestamp - _timestamp; // overflow is desired
        pricesinfo.timeElapsed2 = blockTimestamp2 - _timestamp2; // overflow is desired

        pricesinfo.priceCumulative = _index == 0 ? price0Cumulative : price1Cumulative;
        pricesinfo.priceCumulative3 = _index3 == 0 ? price3Cumulative : price4Cumulative;

        _ethPrice = (pricesinfo.priceCumulative3 - _cumulative2)/pricesinfo.timeElapsed2;

        updateReservedPrice(epoch(), _ethPrice); 
        uint256 windowEthPrice = PoolGetters.reservedPrice(epoch());
        uint256 windowEthPriceLast = PoolGetters.reservedPrice(epoch()-1);
        Decimal.D256 memory one = Decimal.one();
        Decimal.D256 memory shadowEthPrice = one;
        if (windowEthPriceLast>0){
            shadowEthPrice = windowEthPrice>=windowEthPriceLast ? one.add(Decimal.ratio(sqrt(windowEthPrice-windowEthPriceLast),
            sqrt(windowEthPriceLast))) : one.sub(Decimal.ratio(sqrt(windowEthPriceLast-windowEthPrice),sqrt(windowEthPriceLast)));
            }
        Decimal.D256 memory price1 = Decimal.ratio((pricesinfo.priceCumulative - _cumulative)
            / pricesinfo.timeElapsed, 2**112);
        Decimal.D256 memory price = price1.mul(Decimal.ratio(90, 100)).add(shadowEthPrice.div(1e12).mul(Decimal.ratio(10, 100)));

        _timestamp = blockTimestamp;
        _timestamp2 = blockTimestamp2;
        _cumulative = pricesinfo.priceCumulative;
        _cumulative2 = pricesinfo.priceCumulative3;

        return price.mul(1e12);
    }

    function updateReserve() private returns (uint256) {
        uint256 lastReserve = _reserve;
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        _reserve = _index == 0 ? reserve1 : reserve0; // get counter's reserve
        return lastReserve;
    }

    function usdc() internal view returns (address) {
        return Constants.getUsdc();
    }
    function weth() internal view returns (address) {
        return Constants.getWeth();
    }

    function pair() external view returns (address) {
        return address(_pair);
    }

    function reserve() external view returns (uint256) {
        return _reserve;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }


    modifier onlyDao() {
        Require.that(
            msg.sender == _dao,
            FILE,
            "Not dao"
        );

        _;
    }
}