

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.19;


import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


contract Raffle is VRFConsumerBaseV2Plus{
    //errors 
    error Raffle__SendMoreToEnterRaffle();
    error  Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();


    // Typ declarations 
    enum RaffleStates {
        OPEN,               // 0

        CALCULATING //1
    }


    uint16 private constant REQUEST_CONFIRMATIONS=3;
    uint32 private constant NUM_WORDS = 1;


    uint256 private immutable i_entranceFee ;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    address payable []  private s_players;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    // uint16 private immutable i_requestConfirmations ;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;
    uint256 private requestId;

    RaffleStates private s_raffleState ;



    // bool s_calculattingWinner = false ;

    event RaffleEntered(address indexed asdf);
    event WinnerPicked(address indexed winner);




    constructor(uint256 entranceFee ,uint256 interval,address vrfCoordinator,bytes32 gasLane 
    ,uint256 subscriptionId, uint32 callbackGasLimit )
     VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee=entranceFee;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
        // s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit =  callbackGasLimit;
        s_raffleState= RaffleStates.OPEN;

        







    }




    function enterRaffle() public  payable {
        // require(msg.value >= i_entranceFee,"Not enough Eth Sent");
        require(msg.value >=  i_entranceFee,Raffle__SendMoreToEnterRaffle());
        if(msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();

        }

        if(s_raffleState != RaffleStates.OPEN) {
            revert Raffle__RaffleNotOpen();

        }
        s_players.push(payable(msg.sender));
          
        emit RaffleEntered(msg.sender);

    }
    // get a random number 
    //  use that to pic the random user 
    //  
    function pickWinner() external  {
        // check if enough time has passed ;
        if((block.timestamp - s_lastTimeStamp) < i_interval ) {
            revert();

        }
        // get our random number 2.5

        // 1 req RNG;
        // 2 Get RNG 

        s_raffleState = RaffleStates.CALCULATING;



        VRFV2PlusClient.RandomWordsRequest memory request =   VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            }); 

        requestId = s_vrfCoordinator.requestRandomWords(
          request
        );

    }

    
    //   CEI = check , effects (update the effects ) , Interactions (all the trnsactions  that happen)


    function fulfillRandomWords(uint256 , uint256[] calldata randomWords) internal virtual override {
        //effects 
         uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner  = s_players[indexOfWinner];

        s_recentWinner = recentWinner;


        s_raffleState =  RaffleStates.OPEN;
        s_players = new address payable[](0); 
        s_lastTimeStamp=  block.timestamp;
        emit WinnerPicked(s_recentWinner);


        // interactions 
        (bool success,) = recentWinner.call{value : address(this).balance }("");

        if(!success) {
            revert Raffle__TransferFailed();
        }




    }

    // getter functions :-

    function getEntranceFee() external view  returns (uint256) {
        return i_entranceFee;

    }


}