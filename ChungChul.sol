pragma solidity ^0.4.24;

import "./Ownable.sol";

contract ChungChulContract is Ownable {
    
    bytes32[] public lectureIDs; // Lecture ID Array
    mapping(bytes32 => Lecture) internal lectures; // Mapping Lecture struct with ID

    event CreatingLecture(bytes32 indexed id, address indexed teacher, uint lectureCost);
    event EvaluatingLecture(bytes32 indexed lectureID, address indexed evaluater, uint evaluatingCount);
    
    // A Lecture Struct
    struct Lecture {
        bytes32 id; // Lecture ID
        uint index; // Lecture index (Reused Count)
        address teacher; // Teacher Address
        address[] students; // Students Address Array
        uint[5] totalLectureCost; // Total cost collected in a lecture
        uint[5] cost; // Lecture Cost
        uint[5] evaluaterCount; // Number of people who participated in the Evaluation
        bool exists; // isExist Lecture
        
        // Lecture Evaluation Point
        uint[5] preparation_point;
        uint[5] content_point;
        uint[5] proceed_point;
        uint[5] communication_point;
        uint[5] satisfaction_point;
        uint averagePoint;
    }
    
    constructor() public {
        owner = msg.sender; // Admin Wallet Address
    }
    
    /**
    * @dev Get Lecture byte32 ID (For loading the lectrue)
    * @param lectureNumber Unique index number for the lecture
    */
    function getLectureID(uint lectureNumber) public view returns (bytes32 lectureID){
        return lectureIDs[lectureNumber];
    }
    
    /**
    * @dev Get Lecture Evaluation Point and Count by ID
    * @param lectureNumber Unique index number for the lecture
    */
    function getLectureEvaluationPoint(uint lectureNumber) public view returns (uint evaluationCount,
                                                                    uint preparation_point,
                                                                    uint content_point,
                                                                    uint proceed_point,
                                                                    uint communication_point,
                                                                    uint satisfaction_point
                                                                    ){
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture memory lecture = lectures[lectureID];
        
        for (uint index=0; index<=lecture.index; index++) {
            evaluationCount += lecture.evaluaterCount[index];
            preparation_point += lecture.preparation_point[index];
            content_point += lecture.content_point[index];
            proceed_point += lecture.proceed_point[index];
            communication_point += lecture.communication_point[index];
            satisfaction_point += lecture.satisfaction_point[index];
        }
        return (evaluationCount, preparation_point, content_point, proceed_point, communication_point, satisfaction_point);
    }
    
    /**
    * @dev Get Lecture Total Cost for Lecture ID
    * @param lectureNumber Unique index number for the lecture
    */
    function getLectureTotalCost(uint lectureNumber) public view returns(uint totalLectureCost) {
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture memory lecture = lectures[lectureID];

        for (uint index=0; index<=lecture.index; index++) {
            totalLectureCost += lecture.totalLectureCost[index];
        }
        return totalLectureCost;
    }
    
    /**
    * @dev Create Lecture by Teacher (Used for the first creation of a lecture)
    * @param lectureCost Lecture Fee determined by the teacher
    */
    function createLecture(uint lectureCost) public {
        bytes32 id = keccak256(abi.encodePacked(block.number, msg.sender, lectureCost));
        lectureIDs.push(id);
        
        Lecture storage lecture = lectures[id];
        if(!lecture.exists) {
            lecture.id = id;
            lecture.index = 0;
            lecture.teacher = msg.sender;
            lecture.cost[0] = lectureCost;
            lecture.exists = true;
            
            lecture.evaluaterCount[0] = 0;
            lecture.preparation_point[0] = 0;
            lecture.content_point[0] = 0;
            lecture.proceed_point[0] = 0;
            lecture.communication_point[0] = 0;
            lecture.satisfaction_point[0] = 0;
            lecture.averagePoint = 0;
            
            emit CreatingLecture(id, msg.sender, lectureCost);
        }
    }
    
    /**
    * @dev Re-create a previously performed lecture (Maximum limited 4 times by lecture struct index)
    * @param lectureNumber Unique index number for the lecture
    * @param lectureCost Lecture Fee determined by the teacher
    */
    function recreateLecture(uint lectureNumber, uint lectureCost) public {
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture storage lecture = lectures[lectureID];
        
        require(lecture.teacher == msg.sender);
        require(!lecture.exists);
        
        if (lecture.index < 4){
            lecture.exists = true;
            lecture.index += 1;
            lecture.cost[lecture.index] = lectureCost;
            lecture.evaluaterCount[lecture.index] = 0;
            lecture.preparation_point[lecture.index] = 0;
            lecture.content_point[lecture.index] = 0;
            lecture.proceed_point[lecture.index] = 0;
            lecture.communication_point[lecture.index] = 0;
            lecture.satisfaction_point[lecture.index] = 0;
            
        emit CreatingLecture(lectureID, msg.sender, lectureCost); 
        
        } else {
            revert();
        }
    }
    
    /**
    * @dev Purchase Lecture by Student (Must be set the same Value as the lecture's cost that is created)
    * @param lectureNumber Unique index number for the lecture
    */
    function purchaseLecture(uint lectureNumber) public payable {
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture storage lecture = lectures[lectureID];
        require(lecture.exists);
        
        uint lectureCostConvertToWei = lecture.cost[lecture.index] * 10 ** 18;
        require(msg.value == lectureCostConvertToWei);
        
        lecture.totalLectureCost[lecture.index] += msg.value;
        lecture.students.push(msg.sender);
    }
    
    /**
    * @dev Validating whether a lecture has been purchased by msg.sender(student)
    * @param lectureNumber Unique index number for the lecture
    * @param studentAddress msg.sender by student
    */
    function isValidStudent(uint lectureNumber, address studentAddress) public view returns (bool isValid){
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture memory lecture = lectures[lectureID];
        
        for (uint i = 0; i < lecture.students.length; i++){
            if (studentAddress == lecture.students[i]){
                isValid = true;
                break;
            } else {
                isValid = false;
            }
        }
        return isValid;
    }
    
    /**
    * @dev Evaluate lecture by Student (Only student who have purchased the lecture can evaluate)
    */
    function evaluateLecture(
        uint lectureNumber,
        uint _preparation_point,
        uint _content_point,
        uint _proceed_point,
        uint _communication_point,
        uint _satisfaction_point
        ) public {
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture storage lecture = lectures[lectureID];
        require(lecture.exists);
        
        if (isValidStudent(lectureNumber, msg.sender) == false){
            revert();
        }
        
        lecture.evaluaterCount[lecture.index] += 1;
        lecture.preparation_point[lecture.index] += _preparation_point;
        lecture.content_point[lecture.index] += _content_point;
        lecture.proceed_point[lecture.index] += _proceed_point;
        lecture.communication_point[lecture.index] += _communication_point;
        lecture.satisfaction_point[lecture.index] += _satisfaction_point;
        
        emit EvaluatingLecture(lectureID, msg.sender, lecture.evaluaterCount[lecture.index]);
    }
    
    /**
    * @dev View the overall average evaluation point for the lecture by Lecture ID
    * @param lectureNumber Unique index number for the lecture
    */
    function calculateEvaluationAveragePoint(uint lectureNumber) public view returns(uint averagePoint){
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture memory lecture = lectures[lectureID];
        averagePoint = 0;
        
        uint totalPoint = 0;
        uint totalEvaluaterCount = 0;
                        
        for (uint index=0; index<=lecture.index; index++) {
            totalPoint += lecture.preparation_point[index] + 
                        lecture.content_point[index] + 
                        lecture.proceed_point[index] + 
                        lecture.communication_point[index] + 
                        lecture.satisfaction_point[index];
            totalEvaluaterCount += lecture.evaluaterCount[index];
        }
        averagePoint = totalPoint / (totalEvaluaterCount * 5);

        return averagePoint;
    }
    
    /**
    * @dev Contract distributer approve Escrow System using Ownable
    * @param lectureNumber Unique index number for the lecture
    */
    function acceptAdmin(uint lectureNumber) external onlyOwner {
        payBalance(lectureNumber);
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture storage lecture = lectures[lectureID];
        lecture.exists = false;
        lecture.totalLectureCost[lecture.index] = 0;
    }
    
    /**
    * @dev Calculate incentive amount for a lecture
    * @param lectureFee Lecture Fee determined by the teacher
    * @param percent Decimal percentage
    */
    function calculateIncentiveCost(uint lectureFee, uint percent) public view returns(uint incentiveCost){
        incentiveCost = 0;
        incentiveCost = (lectureFee * percent + 50) / 100; // Round off to the nearest tenth
        return incentiveCost;
    }
    
    /**
    * @dev Pay teacher based on lecture's average evaluation point and rest are fees.
    * @param lectureNumber Unique index number for the lecture
    */
    function payBalance(uint lectureNumber) public payable {
        bytes32 lectureID = getLectureID(lectureNumber);
        Lecture memory lecture = lectures[lectureID];
        
        lecture.averagePoint = calculateEvaluationAveragePoint(lectureNumber);
        uint lectureFee = lecture.totalLectureCost[lecture.index] / 10;
        uint toTeacherCost = lecture.totalLectureCost[lecture.index] - lectureFee;

        if (lecture.averagePoint == 100) { // Incentive 15%
            toTeacherCost += calculateIncentiveCost(lectureFee, 15);
        } else if (lecture.averagePoint >= 80 && lecture.averagePoint < 100){ // Incentive 10%
            toTeacherCost += calculateIncentiveCost(lectureFee, 10);
        } else if (lecture.averagePoint >= 60 && lecture.averagePoint < 80){  // Incentive 5%
            toTeacherCost += calculateIncentiveCost(lectureFee, 5);
        } else { // Incentive 0%
            // No Incentive
        }
        lecture.teacher.transfer(toTeacherCost);
        owner.transfer(lecture.totalLectureCost[lecture.index] - toTeacherCost);
    }
}
