//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

import "./utils/Context.sol";
import "./security/ReentrancyGuard.sol";
import "./interface/IOracle.sol";
import "./interface/IERC20.sol";

contract INRT is Context, ReentrancyGuard {
    address public DAI;
    address public Oracle;

    string public name = "Stable INR";
    string public symbol = "INRT";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;

    /**
     * DAI Testing for Kovan :
     * 0x9cd539ac8dca5757efac30cd32da20cd955e0f8b
     *
     * INR-DAI Price Oracle:
     * 0x2275Bad4e366eE3AE0bA4daABE31c014cCD39bd9
     */
    constructor() public {
        DAI = 0x9CD539Ac8Dca5757efAc30Cd32da20CD955e0f8B;
        Oracle = 0x2275Bad4e366eE3AE0bA4daABE31c014cCD39bd9;
    }

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _deposits;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    function mint(uint256 _dai) public virtual nonReentrant returns (uint256) {
        uint256 balance = IERC20(DAI).balanceOf(_msgSender());
        require(balance >= _dai, "Error: insufficient dai balance");

        uint256 allowance = IERC20(DAI).allowance(_msgSender(), address(this));
        require(allowance >= _dai, "Error: insufficient allowance");

        uint256 price = IOracle(Oracle).rupeePrice();
        uint256 amount = (_dai * price) / 10**2;

        _balances[_msgSender()] += amount;
        _deposits[_msgSender()] += _dai;

        totalSupply += amount;
        IERC20(DAI).transferFrom(_msgSender(), address(this), _dai);

        emit Transfer(address(0), _msgSender(), amount);
        return amount;
    }

    function redeem(uint256 _inrt)
        public
        virtual
        nonReentrant
        returns (uint256)
    {
        uint256 allowance = _allowances[_msgSender()][address(this)];
        uint256 balance = _balances[_msgSender()];
        require(balance >= _inrt, "Error: insufficient inrt balance");
        require(allowance >= _inrt, "Error: insufficient allowance");

        uint256 _dai = (_deposits[_msgSender()] * _inrt) / balance;

        _deposits[_msgSender()] -= _dai;
        totalSupply -= _inrt;

        _balances[_msgSender()] -= _inrt;
        _balances[address(0)] += _inrt;

        _allowances[_msgSender()][address(this)] -= _inrt;

        IERC20(DAI).transfer(_msgSender(), _dai);

        emit Transfer(_msgSender(), address(0), _inrt);
        return _dai;
    }

    function balanceOf(address user) public view virtual returns (uint256) {
        return _balances[user];
    }

    function depositOf(address user) public view virtual returns (uint256) {
        return _deposits[user];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        require(
            _balances[_msgSender()] >= amount,
            "Error: insufficient balance"
        );

        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowance = _allowances[_from][_msgSender()];
        uint256 balance = _balances[_from];
        require(balance >= amount, "Error: insufficient inrt balance");
        require(allowance >= amount, "Error: insufficient allowance");

        _balances[_from] -= amount;
        _balances[_to] += amount;

        _allowances[_from][_msgSender()] -= amount;

        emit Transfer(_from, _to, amount);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _allowances[_msgSender()][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[_owner][_spender];
    }
}
