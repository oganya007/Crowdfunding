// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import the interface file
import "./intercrowdfund.sol";

 //create an event named launch which comprises of id, creator, goal, startAt, endAt 
contract classwork{
    event Launch(
        uint id,
        uint id,
         //indexed used to filter event for specific values
         //usinfg indexed stores it as a topic in the log record, without it, it will be stored as data
        address indexed creator,   
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event cancel(
        uint id
    );

    event pledge(
        uint indexed id,
        address indexed caller,
        uint amount 
    );

     event unpledge(
        uint indexed id,
        address indexed caller,
        uint amount
     );

     event claim(
         uint id
     );

     event refund(
         uint id,
         //indexed used to filter event for specific values
         //usinfg indexed stores it as a topic in the log record, without it, it will be stored as data
         address indexed caller,
         uint amount
     );
      
      struct Campaign{
          //creator of campaign
          address creator;
          //amount to be raised
          uint goal;
          //amount pledged
          uint pledged;
          //timestampof start of campaign
          uint32 startAt;
          //timestamp of stop of campaign
          uint32 endAt;
          //true if goal is reached and creator has claimed the token
          bool claimed; 
      }

         IERC20 public immutable token; //making reference to the ERC20 token- a state variable
//total count of campaigns created
//it is also used to generate id for new campaigns
uint public count; //a state variable to capture count later on
//mapping from id to campaign
mapping(uint => Campaign) public campaigns;
//nested mapping to capture the campaign id=> pledger => amount pledged
mapping(uint => mapping(address => uint))public pledgedAmount;

constructor(address _token){
    token = IERC20(_token);
}

    function launch(uint _goal, uint32 _startAt, uint32 _endAt)external{
       require(_startAt >= block.timestamp, "startAt < now"); //now-exact time you deployed the contract
       require(_endAt >= _startAt, "endAt < startAt");//set the time to end
       require(_endAt <= block.timestamp + 90 days, "endAt > maxduration");
//anywhere count is called, to be able to count and increase campaign id
       count += 1;
//campaigns[1] = Campaign(msg.sender, 1000, 0, 2pm, 4pm, false);
campaigns[count] = Campaign(msg.sender, _goal, 0, _startAt, _endAt, false);
//declare name of struct, then put in contents of the struct
//then equate it to your mapping, inside my mapping,we'll have count inside

emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
//you can only cancel if the campaign hasn't started
    function Cancel(uint _id) external{
    Campaign memory campaign = campaigns[_id]; //index it like an array
    require(campaign.creator == msg.sender, "You are not the creator");
    require(block.timestamp < campaign.startAt, "The campaign has started");

    delete campaigns[_id];
    emit cancel(_id);
    }

    function Pledge(uint _id, uint _amount) external{
        //to allow you enter the struct, use Campaign memory campaign = campaigns[_id];
        Campaign storage campaign = campaigns[_id];// storage since we are updating struct, storing permanently
        require(block.timestamp >= campaign.startAt,  "Campaign has not started");
        require(block.timestamp <= campaign.endAt, "Campaign has ended");
        //total supply, as people are adding the total ampount is increasing
        campaign.pledged += _amount;
        //mapping for pledged amount, this line shows the particular pledge and id and address in case of returns
        pledgedAmount[_id][msg.sender] += _amount; //ID IS THE ID OF THE CAMPAIGN
        //removes money from your exchange to the campaign
        //(ADDRESS OF THE INSTANCE OF THIS CONTRACT NOT CREATOR, IT GOES TO CREATOR WHEN COMPLETE
        token.transferFrom(msg.sender, address(this), _amount);
        //the person pledging is the caller-msg.sender
        emit pledge(_id, msg.sender, _amount);

    }
    function Unpledge(uint _id, uint _amount) external{
        Campaign storage campaign = campaigns[_id];//storage cos we are updating the struct
    require(block.timestamp <= campaign.endAt,"Campaign has ended");
    campaign.pledged -= _amount;
    pledgedAmount[_id][msg.sender] -= _amount;

    token.transfer(msg.sender, _amount);
    emit unpledge(_id, msg.sender, _amount);
    }

    function Claim(uint _id) external{
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "You are not the owner");
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged >= campaign.goal,"Amount realized less than goal");
        //require that the campaign is not claimed 
        require(!campaign.claimed, "CAMPAIGN HAS BEEN CLAIMED");

        campaign.claimed = true;//means all requirements are met
        //transfer to the creator
        token.transfer(campaign.creator, campaign.pledged);
        emit claim(_id);
    }

    function Refund(uint _id) external{
        Campaign memory campaign = campaigns[_id]; 
        //memory cos we want to take out everything so no need storing permanently
        require(block.timestamp > campaign.endAt, "Campaign has ended");
        require(campaign.pledged < campaign.goal,"pledge >= Goal");

        //using a mapping to check how much you have and saving in a variable called balance  
        uint balance = pledgedAmount[_id][msg.sender];
        
        //nullify what was given
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance);
        emit refund(_id, msg.sender, balance);
        
    }
   function second() public view returns(uint){
    return block.timestamp;
} 
}
