// symlink Voting.json to: ../../artifacts/contracts/Voting.sol/Voting.json
// import VotingContract from "./Voting.json";
import PollFactory from "./contract_abi/PollFactory.sol/PollFactory.json"
import {ethers} from "ethers";
import store from "./redux/store";

const ContractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

function blockchainInitialized(data) {
    return {
        type: "BLOCKCHAIN_INITIALIZED",
        payload: data
    };
}

const initBlockchain = async () => {
    let provider;
    window.ethereum.enable()
      .then(provider = new ethers.providers.Web3Provider(window.ethereum));

    const signer = await provider.getSigner();
    console.log('signer:', signer);

    const userAddress = await signer.getAddress();
    console.log("userAddress:", userAddress);

    console.log(PollFactory);
    // the below is not necessary and breaks the code
    // const parsedAbi = JSON.parse(PollFactory.abi);
    let contract = new ethers.Contract(ContractAddress, PollFactory.abi, signer);


    let data = {provider, signer, contract, userAddress};
    store.dispatch(blockchainInitialized(data));
    console.log("initBlockchain end");
    return data;
}

export default initBlockchain;
