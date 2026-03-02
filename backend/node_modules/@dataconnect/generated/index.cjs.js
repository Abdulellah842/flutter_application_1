const { queryRef, executeQuery, mutationRef, executeMutation, validateArgs } = require('firebase/data-connect');

const connectorConfig = {
  connector: 'example',
  service: 'backend',
  location: 'us-east4'
};
exports.connectorConfig = connectorConfig;

const listAllChatsRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'ListAllChats');
}
listAllChatsRef.operationName = 'ListAllChats';
exports.listAllChatsRef = listAllChatsRef;

exports.listAllChats = function listAllChats(dc) {
  return executeQuery(listAllChatsRef(dc));
};

const getMyProfileRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetMyProfile');
}
getMyProfileRef.operationName = 'GetMyProfile';
exports.getMyProfileRef = getMyProfileRef;

exports.getMyProfile = function getMyProfile(dc) {
  return executeQuery(getMyProfileRef(dc));
};

const createChatMessageRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'CreateChatMessage', inputVars);
}
createChatMessageRef.operationName = 'CreateChatMessage';
exports.createChatMessageRef = createChatMessageRef;

exports.createChatMessage = function createChatMessage(dcOrVars, vars) {
  return executeMutation(createChatMessageRef(dcOrVars, vars));
};

const addUserToChatRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddUserToChat', inputVars);
}
addUserToChatRef.operationName = 'AddUserToChat';
exports.addUserToChatRef = addUserToChatRef;

exports.addUserToChat = function addUserToChat(dcOrVars, vars) {
  return executeMutation(addUserToChatRef(dcOrVars, vars));
};
