pragma solidity ^0.6.0;

interface IOracle {
    function rupeePrice() external view returns (uint256);

    function requestRupeePrice() external returns (bytes32 requestId);

    function requestAll() external;

    function fulfillRupee(bytes32 _requestId, uint256 _price) external;
}
