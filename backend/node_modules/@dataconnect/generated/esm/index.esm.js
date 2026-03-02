import { queryRef, executeQuery, mutationRef, executeMutation, validateArgs } from 'firebase/data-connect';

export const connectorConfig = {
  connector: 'example',
  service: 'backend',
  location: 'us-east4'
};

export const listAllChatsRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'ListAllChats');
}
listAllChatsRef.operationName = 'ListAllChats';

export function listAllChats(dc) {
  return executeQuery(listAllChatsRef(dc));
}

export const getMyProfileRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetMyProfile');
}
getMyProfileRef.operationName = 'GetMyProfile';

export function getMyProfile(dc) {
  return executeQuery(getMyProfileRef(dc));
}

export const createChatMessageRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'CreateChatMessage', inputVars);
}
createChatMessageRef.operationName = 'CreateChatMessage';

export function createChatMessage(dcOrVars, vars) {
  return executeMutation(createChatMessageRef(dcOrVars, vars));
}

export const addUserToChatRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddUserToChat', inputVars);
}
addUserToChatRef.operationName = 'AddUserToChat';

export function addUserToChat(dcOrVars, vars) {
  return executeMutation(addUserToChatRef(dcOrVars, vars));
}

