pragma solidity ^0.5.0;

//ERC20 interface
contract IERC20 {
    uint public totalSupply = 0;

    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) allowed;

    function balanceOf(address who) public view returns (uint); //
    function allowance(address owner, address spender) public view returns (uint);  //
    function transfer(address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);    
    function transferFrom(address from, address to, uint value) public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );
}
