// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.28;

contract ReputationVanet {
    constructor(address[] memory _owners) {
        uint256 ownersLength = _owners.length;
        require(
            ownersLength >= requiredOwnersConfirmation,
            "Input less than requirement"
        );
        for (uint256 i; i < ownersLength; ) {
            // require(owner != address(0), "invalid owner");
            owners[_owners[i]] = true;
            unchecked {
                ++i;
            }
        }
        ownerCount = ownersLength;

        // Fuzzy Logic
        // describe terms for each variable
        input.terms[1].mfParams = [0, 0, 200, 400]; // low
        input.terms[2].mfParams = [300, 500, 700, 900]; // medium
        input.terms[3].mfParams = [700, 900, 1000, 1000]; // high

        output.terms[1].mfParams = [0, 0, 0, 200]; // very low
        output.terms[2].mfParams = [0, 200, 200, 400]; // low
        output.terms[3].mfParams = [300, 500, 500, 700]; // medium
        output.terms[4].mfParams = [600, 800, 800, 1000]; // high
        output.terms[5].mfParams = [800, 1000, 1000, 1000]; // very high

        // describe system rules
        // It's important to preserve the same order in description
        // as you had when defined inputs
        rules[0].conditions = [1, 1];
        rules[0].conclusion = 1; // very low

        rules[1].conditions = [1, 2];
        rules[1].conclusion = 2; // low

        rules[2].conditions = [1, 3];
        rules[2].conclusion = 3; // medium

        rules[3].conditions = [2, 1];
        rules[3].conclusion = 2; // low

        rules[4].conditions = [2, 2];
        rules[4].conclusion = 3; // medium

        rules[5].conditions = [2, 3];
        rules[5].conclusion = 4; // high

        rules[6].conditions = [3, 1];
        rules[6].conclusion = 3; // medium

        rules[7].conditions = [3, 2];
        rules[7].conclusion = 4; // high

        rules[8].conditions = [3, 3];
        rules[8].conclusion = 5; // very high
    }

    struct ownerFunctionTransaction {
        uint40 functionID;
        address sender;
        address[] addressList;
        mapping(address => bool) confirmList;
        bool executed;
        uint256 confirmations;
    }

    struct Node {
        bool preTrust;
        mapping(uint256 => Event) events;
        uint256 eventsLength;
        mapping(uint256 => bool) eventsIDIndex;
        uint40 currentReputation;
        bool exist;
    }

    struct Event {
        /**
         * Create event feedback gathering contract.
         *
         * @param _eventID ID of event
         * @param _eventType Type of event based on importance 0=Minor Event, 1=Moderate Event, 2=Severe Event
         *
         */
        uint256 eventID;
        uint256 eventIndex;
        uint40 eventType;
        uint40 criticalFactor;
        uint256 timestamp; // timestamp of when event is created
        uint40 eventDuration;
        uint40 msgTrustValue; // trust value for massage accuracy
        uint40 locTrustValue; // trust value for location accuracy
        uint40 msgTrustWeight; // weight of accumulated feedbacks for message
        uint40 locTrustWeight;
        uint256[2] coordinate;
        address rsuAddress; // associated RSU address that receive the event
        mapping(address => EventFeedbackProvider) providers; // list of permit feedback providers
    }

    struct EventFeedbackProvider {
        uint40 weight; // weight that this provider have for feedback
        bool sent; // if true, that entity already sent feedback
        bool msgFeedback; // massage feedback value
        bool locFeedback; // location feedback value
    }

    struct LinguisticVariable {
        /**
         * Describes a Linguistic Variable - parameter for fuzzy inference system
         * It is a linguistic expression (one or more words) labeling an information
         * range always 0 to 10
         */
        bool isTrue;
        mapping(uint8 => Term) terms;
    }

    struct Rule {
        /**
         * Describe a rule for fuzzy inference system.
         * Rule is:
         * 1) Matching for every linguistic variable with one of it terms.
         * 2) connection "And" only available for this implementation
         * 3) Weight coefficient of Rule. Or how much rule will effort on system's conclusion. We assume weight always 1 here
         */
        uint8[2] conditions;
        uint8 conclusion;
    }

    struct Term {
        /**
         * Describes Term for linguistic variables.
         * Term is a fuzzy definition of some variable. Like 'tall', 'low' - about height
         * mfType type of membership functions. Only trapezoidal available
         * uint256 mapping;  // replace name to save gas with level instead like 0, 1, 2
         */
        bool isTrue;
        uint40[4] mfParams; //  mfParams parameters of the membership function.
    }

    struct CorrectedTerm {
        /**
         * Describes Term limited by belief degree.
         */
        uint40[4] mfParams; //  mfParams parameters of the membership function from term.
        uint40 beliefDegree; // number
    }

    mapping(address => bool) public owners;
    uint256 public requiredOwnersConfirmation = 1; // number of owner required for transaction to be confirmed
    uint256 public ownerTransactionCount;
    uint256 public ownerCount;

    mapping(uint256 => ownerFunctionTransaction) public ownerTransactions;

    mapping(address => Node) public nodes;
    mapping(address => bool) public rsus;

    uint40[5] internal eventTypeDuration = [600, 1800, 3600, 7200, 7200]; // Event duration in seconds for each event type index

    // Value is in scale of 1 = 1000
    uint40[5] internal eventRepRequirement = [200, 400, 600, 700, 900]; // Reputation value requirement for each event critical level
    //

    // Value is in scale of 1 = 100
    uint40[5] internal eventCriticalLevelFactor = [100, 150, 200, 300, 400]; // Critical level factor to event trust weight for each critical level
    // Time decay alpha value
    // NOTE: this list is time decay by day with alpha span 2 / 31
    // The value must be changed for different alpha
    uint40[69] internal timeDecayList = [
        100, // day 0
        93,
        87,
        81,
        76,
        71,
        66,
        62,
        58,
        54,
        51,
        47,
        44,
        41,
        39,
        36,
        34,
        31,
        29,
        27,
        26,
        24,
        22,
        21,
        19,
        18,
        17,
        16,
        15,
        14,
        13,
        12,
        11,
        10,
        10,
        9,
        8,
        8,
        7,
        7,
        6,
        6,
        5,
        5,
        5,
        4,
        4,
        4,
        3,
        3,
        3,
        3,
        3,
        2,
        2,
        2,
        2,
        2,
        2,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1 // day 68
    ];
    //

    // Fuzzy vairables
    LinguisticVariable internal input;
    LinguisticVariable internal output;
    mapping(uint8 => Rule) internal rules;

    // MODIFIERS
    modifier onlySmartContractOwner() {
        require(owners[msg.sender], "Only owner can perform this task");
        _;
    }

    modifier onlyNode() {
        require(nodes[msg.sender].exist, "Node not existed");
        _;
    }

    function submitEvent(
        uint256 eventID,
        uint40 eventType,
        uint256[2] memory coordinate,
        address rsuAddress
    ) external onlyNode returns (bool) {
        unchecked {
            Node storage node = nodes[msg.sender];
            require(!node.eventsIDIndex[eventID], "Event ID already existed");
            require(rsus[rsuAddress], "RSU not exist");
            (uint40 msgNumerator, uint40 locNumerator) = feedbackAggregation(
                msg.sender
            );
            node.currentReputation = currentReputation(
                msgNumerator,
                locNumerator
            );
            // can only submit event if reputation pass threshold
            if (node.currentReputation >= eventRepRequirement[eventType]) {
                Event storage newEvent = node.events[node.eventsLength];
                node.eventsIDIndex[eventID] = true;
                newEvent.eventID = eventID;
                newEvent.eventType = eventType;
                newEvent.timestamp = block.timestamp; // timestamp of when event is created
                newEvent.coordinate = coordinate;
                newEvent.rsuAddress = rsuAddress;
                newEvent.criticalFactor = eventCriticalLevelFactor[eventType];
                newEvent.eventDuration = eventTypeDuration[eventType];
                ++node.eventsLength;
                return true;
            } else {
                return false;
            }
        }
    }

    function addTestEvent() external {
        for (uint8 p; p < 50; ) {
            Node storage node = nodes[msg.sender];
            Event storage newEvent = node.events[node.eventsLength];
            node.exist = true;
            node.eventsIDIndex[node.eventsLength] = true;
            newEvent.eventID = node.eventsLength;
            newEvent.eventType = 1;
            newEvent.timestamp = block.timestamp; // timestamp of when event is created
            newEvent.eventDuration = eventTypeDuration[1];
            newEvent.msgTrustValue = 30;
            newEvent.locTrustValue = 30;
            newEvent.msgTrustWeight = 100;
            newEvent.locTrustWeight = 100;
            newEvent.criticalFactor = 100;
            unchecked {
                ++p;
            }
            ++node.eventsLength;
        }
    }

    /*
     * @dev Give 'providers' the right to send feedback in this process. May only be called by 'owner' and process not ended.
     * @param address list of feedback providers
     */
    function giveEventFeedbackRight(
        address eventOwnerAddress,
        uint256 eventIndex,
        address[] memory providerList
    ) external {
        unchecked {
            Event storage thisEvent = nodes[eventOwnerAddress].events[
                eventIndex
            ];
            require(
                block.timestamp - thisEvent.timestamp <=
                    thisEvent.eventDuration,
                "Event already expired"
            );
            require(
                msg.sender == thisEvent.rsuAddress,
                "You are not event's RSU"
            );
            uint256 providerListLength = providerList.length;
            for (uint256 p; p < providerListLength; ) {
                require(
                    eventOwnerAddress != providerList[p],
                    "Can not give right to event owner."
                );
                require(
                    !thisEvent.providers[providerList[p]].sent,
                    "Already sent feedback."
                );
                if (nodes[providerList[p]].preTrust) {
                    // pre-trusted node
                    thisEvent.providers[providerList[p]].weight = 500; // @param change pretrust weight as appropiate
                } else {
                    thisEvent.providers[providerList[p]].weight = 100; // @param change node weight as appropiate
                }
                ++p;
            }
        }
    }

    /*
     * @dev Give feedback (including weight delegated to provider) to event.
     * @param choice index of choice in the choices array
     */
    function giveFeedback(
        address eventOwnerAddress,
        uint256 eventIndex,
        bool msgTrust,
        bool locTrust
    ) external {
        unchecked {
            Event storage thisEvent = nodes[eventOwnerAddress].events[
                eventIndex
            ];
            EventFeedbackProvider storage sender = thisEvent.providers[
                msg.sender
            ];
            require(
                block.timestamp - thisEvent.timestamp <=
                    thisEvent.eventDuration,
                "Event already expired"
            );
            require(!sender.sent, "Already sent feedback.");
            sender.sent = true;
            sender.msgFeedback = msgTrust;
            sender.locFeedback = locTrust;
            uint40 msgPenalty = 100;
            uint40 locPenalty = 100;
            uint40 senderWeight = (sender.weight * thisEvent.criticalFactor) /
                100;
            if (msgTrust) {
                thisEvent.msgTrustValue += senderWeight;
            } else {
                msgPenalty += 25; // @param change penalty factor as appropiate
            }
            if (locTrust) {
                thisEvent.locTrustValue += senderWeight;
            } else {
                locPenalty += 25; // @param change penalty factor as appropiate
            }
            thisEvent.msgTrustWeight += (senderWeight * msgPenalty) / 100;
            thisEvent.locTrustWeight += (senderWeight * locPenalty) / 100;
        }
    }

    /*
     * @dev Get trust value inputs for message and location from all events within limit
     * @dev The two values can then be used for Fuzzy function in Repcal contact
     */

    function feedbackAggregation(address nodeAddress)
        public
        view
        returns (uint40 msgNumerator, uint40 locNumerator)
    {
        unchecked {
            uint256 currentTime = block.timestamp;

            // add default reputation score at the end with 0.5 score and weight of 100 (10000)
            msgNumerator = 500000;
            locNumerator = 500000;
            uint40 msgDenominator = 10000;
            uint40 locDenominator = 10000;
            Node storage thisNode = nodes[nodeAddress];
            mapping(uint256 => Event) storage eventList = thisNode.events;
            uint256 eventsLength = thisNode.eventsLength;
            uint40 eventLifeTimeCheck = 500; // @param change event check limit as appropiate
            for (uint256 p = eventsLength; p != 0; ) {
                Event storage thisEvent = eventList[p - 1];
                uint256 timeDifference = (currentTime - thisEvent.timestamp) /
                    86400; // difference in days
                if (timeDifference > 68) {
                    // @param change event time limit as appropiate, should depend on decay factor
                    break; // stop loop and discard all events onwards that are far too old;
                }
                if (thisEvent.msgTrustWeight != 0) {
                    // event has feedback
                    // exponetial time decay smooth trust and weight
                    uint40 timeExpoAlphaDecay = timeDecayList[timeDifference];
                    msgNumerator +=
                        (timeExpoAlphaDecay * thisEvent.msgTrustValue) /
                        100;
                    locNumerator +=
                        (timeExpoAlphaDecay * thisEvent.locTrustValue) /
                        100;
                    msgDenominator +=
                        (timeExpoAlphaDecay * thisEvent.msgTrustWeight) /
                        100;
                    locDenominator +=
                        (timeExpoAlphaDecay * thisEvent.locTrustWeight) /
                        100;

                    --eventLifeTimeCheck; // only count event with feedback for lifetime check
                    if (eventLifeTimeCheck == 0) {
                        break; // discard all previous events that exceed event limit;
                    }
                }
                --p;
            }
            // find weighted average and convert value to fuzzy function scale where 1 = 1000
            msgNumerator = (msgNumerator * 1000) / msgDenominator;
            locNumerator = (locNumerator * 1000) / locDenominator;
        }
    }

    function valueAtUnionOfTerms(CorrectedTerm[9] memory union, uint40 x)
        internal
        pure
        returns (
            uint40 max // max value from all Terms
        )
    {
        unchecked {
            for (uint8 p; p < 9; ) {
                CorrectedTerm memory term = union[p];
                uint40 check;
                uint40 belief = term.beliefDegree;

                if (belief != 0) {
                    check = valueAtTerm(term.mfParams, x);
                }
                if (belief <= check) {
                    check = belief;
                }
                if (check > max) {
                    max = check;
                }
                ++p;
            }
        }
    }

    function valueAtTerm(uint40[4] memory mfParams, uint40 x)
        internal
        pure
        returns (uint40)
    {
        /**
         * Trapezoidal membership function.
         * @param {number} x
         * @param {number} 0 left f(left) = 0
         * @param {number} 1 maxLeft f(maxLeft) = 1
         * @param {number} 2 maxRight f(maxRight) = 1
         * @param {number} 3 right f(right) = 0
         * @returns {number}
         */
        unchecked {
            uint40 mfParams0 = mfParams[0];
            uint40 mfParams1 = mfParams[1];
            uint40 mfParams2 = mfParams[2];
            uint40 mfParams3 = mfParams[3];
            if (x < mfParams0 || x > mfParams3) {
                return 0;
            } else if (mfParams0 <= x && x <= mfParams1) {
                return ((x - mfParams0) * 1000) / (mfParams1 - mfParams0);
            } else if (mfParams1 <= x && x <= mfParams2) {
                return 1000;
            }
            return ((mfParams3 - x) * 1000) / (mfParams3 - mfParams2);
        }
    }

    /*
     * @dev Calculate reputation score with fuzzy logic
     * @param message and location trust score
     */
    function currentReputation(uint40 inputValue1, uint40 inputValue2)
        internal
        view
        returns (uint40 result)
    {
        unchecked {
            CorrectedTerm[9] memory union;
            for (uint8 i; i < 9; ) {
                // for each Rule get values at the right parts
                uint40 min = 1000;
                Rule memory thisRule = rules[i];
                uint40 checkValue = valueAtTerm(
                    input.terms[thisRule.conditions[0]].mfParams,
                    inputValue1
                );
                if (checkValue < min) {
                    min = checkValue;
                }
                checkValue = valueAtTerm(
                    input.terms[thisRule.conditions[1]].mfParams,
                    inputValue2
                );
                if (checkValue < min) {
                    min = checkValue;
                }
                union[i] = CorrectedTerm(
                    output.terms[thisRule.conclusion].mfParams,
                    min
                );
                ++i;
            }

            // Get mass center
            uint40 s;
            while (result < 1000) {
                result += 10;
                s += (10 * valueAtUnionOfTerms(union, result));
            }
            result = 0;
            uint40 newS;
            s = s >> 1; // divide by 2
            while (newS < s) {
                result += 10;
                newS += (10 * valueAtUnionOfTerms(union, result));
            }
            // now it equals to 'mass center'. In prev point S < S/2, in next point  S > S/2
        }
    }

    /*
     * @dev Give feedback (including weight delegated to provider) to event.
     * @param choice index of choice in the choices array
     */
    function checkEvent(address eventOwnerAddress, uint256 eventIndex)
        external
        view
        returns (
            uint256 eventID,
            uint40 eventType,
            uint256 timestamp,
            uint256 msgTrustValue,
            uint256 locTrustValue,
            uint256 msgTrustWeight,
            uint256 locTrustWeight,
            uint256[2] memory coordinate,
            address rsuAddress
        )
    {
        Event storage thisEvent = nodes[eventOwnerAddress].events[eventIndex];
        eventID = thisEvent.eventID;
        eventIndex = thisEvent.eventIndex;
        eventType = thisEvent.eventType;
        timestamp = thisEvent.timestamp;
        msgTrustValue = thisEvent.msgTrustValue;
        locTrustValue = thisEvent.locTrustValue;
        msgTrustWeight = thisEvent.msgTrustWeight;
        locTrustWeight = thisEvent.locTrustWeight;
        coordinate = thisEvent.coordinate;
        rsuAddress = thisEvent.rsuAddress;
    }

    /*
     * @dev Submit owner function transaction for confirmation.
     * @param function intended to be called from the transaction
     * @param address list for function input
     */
    function submitOwnerTransaction(
        uint40 functionID,
        address[] memory addressList
    ) external onlySmartContractOwner {
        require(functionID < 8, "functionID not exist");
        require(addressList.length != 0, "require address input");
        ownerFunctionTransaction storage thisTX = ownerTransactions[
            ownerTransactionCount
        ];
        thisTX.functionID = functionID;
        thisTX.sender = msg.sender;
        thisTX.addressList = addressList;
        confirmOwnerTransaction(ownerTransactionCount);
        ++ownerTransactionCount;
    }

    function confirmOwnerTransaction(uint256 transactionId)
        public
        onlySmartContractOwner
    {
        ownerFunctionTransaction storage thisTX = ownerTransactions[
            transactionId
        ];
        require(!thisTX.executed, "TX already executed");
        require(thisTX.addressList.length != 0, "Event not exist");
        require(!thisTX.confirmList[msg.sender], "You already confirmed");
        thisTX.confirmList[msg.sender] = true;
        ++thisTX.confirmations;
        if (thisTX.confirmations >= requiredOwnersConfirmation) {
            executeTransaction(transactionId);
        }
    }

    function deleteOwnerTransaction(uint256 txIndex)
        external
        onlySmartContractOwner
    {
        ownerFunctionTransaction storage thisTX = ownerTransactions[txIndex];
        require(thisTX.addressList.length != 0, "TX not exist");
        require(thisTX.sender == msg.sender, "Original sender only");
        delete ownerTransactions[txIndex];
    }

    function executeTransaction(uint256 transactionId) internal {
        unchecked {
            ownerFunctionTransaction storage thisTX = ownerTransactions[
                transactionId
            ];

            uint40 functionID = thisTX.functionID;
            if (functionID == 0) {
                // add owners
                addOwners(thisTX.addressList);
            } else if (functionID == 1) {
                // remove owners
                removeOwners(thisTX.addressList);
            } else if (functionID == 2) {
                // add nodes
                addNodes(thisTX.addressList, false, false);
            } else if (functionID == 3) {
                // add pretrust nodes
                addNodes(thisTX.addressList, true, false);
            } else if (functionID == 4) {
                // add rsu nodes
                addNodes(thisTX.addressList, false, true);
            } else if (functionID == 5) {
                // remove nodes
                removeNodes(thisTX.addressList, false);
            } else if (functionID == 6) {
                // remove rsu nodes
                removeNodes(thisTX.addressList, true);
            } else if (functionID == 7) {
                // change owner confirmation number
                changeConfirmationNumber(thisTX.addressList.length);
            }
            thisTX.executed = true;
        }
    }

    /*
     * @dev Add nodes to database.
     * @param address list of nodes
     * @param pretrust nodes classification
     * @param rsu nodes classification
     */
    function addNodes(
        address[] memory addressList,
        bool pretrust,
        bool rsu
    ) internal {
        for (uint256 p; p < addressList.length; ) {
            unchecked {
                if (rsu) {
                    rsus[addressList[p]] = true;
                } else {
                    if (!nodes[addressList[p]].exist) {
                        // Already existed nodes will not be added again
                        nodes[addressList[p]].preTrust = pretrust;
                        nodes[addressList[p]].currentReputation = 500; // @param change default rep value as appropiate
                        nodes[addressList[p]].exist = true;
                    }
                }
                ++p;
            }
        }
    }

    /*
     * @dev Remove nodes from database.
     * @param address list of nodes
     */
    function removeNodes(address[] memory addressList, bool rsu) internal {
        for (uint256 p; p < addressList.length; ) {
            if (rsu) {
                delete rsus[addressList[p]];
            } else {
                delete nodes[addressList[p]];
            }
            unchecked {
                ++p;
            }
        }
    }

    /*
     * @dev Change confirmation requirement.
     * @param address list (address not used but length indicate new number)
     */
    function changeConfirmationNumber(uint256 newNumber) internal {
        require(newNumber != 0, "Cannot be 0");
        require(newNumber <= ownerCount, "Cannot > number of owners");
        requiredOwnersConfirmation = newNumber;
    }

    /*
     * @dev Add owners.
     * @param address list
     */
    function addOwners(address[] memory addressList) internal {
        for (uint256 p; p < addressList.length; ) {
            unchecked {
                if (!owners[addressList[p]]) {
                    owners[addressList[p]] = true;
                    ownerCount += 1;
                }
                ++p;
            }
        }
    }

    /*
     * @dev Remove owners.
     * @param address list
     */
    function removeOwners(address[] memory addressList) internal {
        require(
            ownerCount - addressList.length >= requiredOwnersConfirmation,
            "Owners lower than requirment"
        );
        for (uint256 p; p < addressList.length; ) {
            delete owners[addressList[p]];
            unchecked {
                ++p;
            }
        }
        unchecked {
            ownerCount -= addressList.length;
        }
    }
}
