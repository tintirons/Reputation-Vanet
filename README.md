# Dynamic Reputation Computation and Management Model for VANET Using a Smart Contract

This repository provides the proof-of-concept design of a smart contract for dynamic reputation computation and management in VANET.

The smart contract contains a multi-signature confirmation function for owner-related functions such as node registration, deletion, and multi-signature parameter update.

The reputation computation model incorporates various techniques to provide resistance against reputation manipulation attacks, which are majority weighted voting, confidence factor, exponential trust decay, trust maturity, event lifetime checking, event criticality level factor, penalty factor, and fuzzy logic. 

The smart contract automatically computes vehicles' reputation scores when they submit a new event and will reject the new event if the submitting vehicles have a reputation score lower than the requirement for the event type.

