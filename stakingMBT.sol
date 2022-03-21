// SPDX-License-Identifier: MIT

pragma solidity > 0.7.0 <=0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingMBT is ERC20, ERC20Burnable, Ownable {
     using SafeMath for uint256;
     uint priceOf_1MBT = 0.001 ether;
     address[] internal stakeholders;

   mapping(address => uint256) internal stakes;
   mapping(address => uint256) internal rewards;
   mapping(address => uint256) internal rewardDueDate;

    constructor() ERC20("MyBlockgamesToken", "MBT") {
        _mint(msg.sender, 1000 * 10 ** 18);
    }

     function buyTokens(address _receiver) public payable {
         // since 1 ether = 1000 MBT, 1 MBT = (1  / 10000) = 0.001 ether
        require(msg.value > priceOf_1MBT, "Cost of buying MBT is 1000 MBT per ETH");
        uint numberOf_MBT = msg.value / priceOf_1MBT;
        _mint(_receiver, numberOf_MBT);
    }

    function modifyTokenBuyPrice(uint _priceOf_1MBT)public onlyOwner {
        priceOf_1MBT = _priceOf_1MBT;
    }

   function isStakeholder(address _address) public view returns(bool, uint256) {
       for (uint256 s = 0; s < stakeholders.length; s++) {
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   function addStakeholder(address _stakeholder) internal {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   function removeStakeholder(address _stakeholder) internal {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   function stakeOf(address _stakeholder) public onlyOwner view returns(uint256) {
       return stakes[_stakeholder];
   }

   function totalStakes() public view returns(uint256)
   {
       uint256 _totalStakes = 0;
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
       }
       return _totalStakes;
   }

   function StakeToken(uint256 _stake) public {
       rewardDueDate[msg.sender] = block.timestamp + 7 days;
       _burn(msg.sender, _stake);
       if(stakes[msg.sender] == 0) {
           addStakeholder(msg.sender);
       }
       stakes[msg.sender] = stakes[msg.sender].add(_stake);
   }

   function removeStake(uint256 _stake) public {
       stakes[msg.sender] = stakes[msg.sender].sub(_stake);
       if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
       _mint(msg.sender, _stake);
   }
   
   function rewardOf(address _stakeholder) public view returns(uint256) {
       return calculateReward(_stakeholder);
   }

   function totalRewards() public onlyOwner view returns(uint256) {
       uint256 _totalRewards = 0;
       for (uint256 s = 0; s < stakeholders.length; s++){
           _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
       }
       return _totalRewards;
   }

   function calculateReward(address _stakeholder) public view returns(uint256) {
       return stakes[_stakeholder] / 100;
   }

   function withdrawReward() public
   {
       require(block.timestamp >= rewardDueDate[msg.sender],"You can only claim after 1 week of staking");
       if(block.timestamp >= rewardDueDate[msg.sender]){
           rewards[msg.sender] = calculateReward(msg.sender);
           uint256 reward = rewards[msg.sender];
            rewards[msg.sender] = 0;
            _mint(msg.sender, reward);
            rewardDueDate[msg.sender] = block.timestamp + 1 weeks;
       }
   }
}
