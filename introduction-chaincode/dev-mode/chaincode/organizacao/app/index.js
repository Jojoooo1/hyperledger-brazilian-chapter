// Testing mockup oblige to start new Chaincode in a separate file
import shim from 'fabric-shim';
import Chaincode from './chaincode';

shim.start(new Chaincode());
