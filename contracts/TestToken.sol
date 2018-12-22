pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IERC20.sol";

//Token following ERC20 standard 
contract TestToken is IERC20{
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;

    uint public totalSupply;

    //contract owner address
    //address public owner_;

    event BurntTokens(address investor, uint amount);
    
    /*
    modifier owner {
        require(msg.sender == owner_, "only owner has an access");
        _;
    }
    */

    constructor(string memory tokenName, string memory tokenTicker, uint decimalsNumber ) public {
        //owner_ = ownerInst;
        name = tokenName;
        symbol = tokenTicker;
        decimals = decimalsNumber;
    }

    function getTotalSupply() external view returns (uint) {
        return totalSupply;
    }

    //owner modifier should be here
    function emitTokens(address _owner, uint _amount) external {
        require(_amount > 0, "you can't emit lt 0 tokens");
        balances[_owner] = balances[_owner].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(address(0), _owner, _amount);
    }

    //owner modifier should be here
    function burnTokens(address investor_, uint value_) external {
        require(balances[investor_] > 0, "you have nothing to burn");
        totalSupply = totalSupply.sub(value_);
        balances[investor_] = balances[investor_].sub(value_);
        emit BurntTokens(investor_, value_);
    }

    function balanceOf(address who) public view returns (uint) { //
        return balances[who];
    }

    function transfer(address to, uint value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool) {
        balances[from] = balances[from].sub(value);
        allowed[from][to] = allowed[from][to].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function allowance(address balanceOwner, address spender) public view returns (uint) { //
        return allowed[balanceOwner][spender];
    }
}