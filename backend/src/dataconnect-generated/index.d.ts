import { ConnectorConfig, DataConnect, QueryRef, QueryPromise, MutationRef, MutationPromise } from 'firebase/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;




export interface AddUserToChatData {
  chatParticipant_insert: ChatParticipant_Key;
}

export interface AddUserToChatVariables {
  chatId: UUIDString;
  userId: UUIDString;
  role?: string | null;
}

export interface ChatMessage_Key {
  id: UUIDString;
  __typename?: 'ChatMessage_Key';
}

export interface ChatParticipant_Key {
  chatId: UUIDString;
  userId: UUIDString;
  __typename?: 'ChatParticipant_Key';
}

export interface Chat_Key {
  id: UUIDString;
  __typename?: 'Chat_Key';
}

export interface Contact_Key {
  user1Id: UUIDString;
  user2Id: UUIDString;
  __typename?: 'Contact_Key';
}

export interface CreateChatMessageData {
  chatMessage_insert: ChatMessage_Key;
}

export interface CreateChatMessageVariables {
  chatId: UUIDString;
  encryptedContent: string;
  messageType: string;
}

export interface GetMyProfileData {
  user?: {
    id: UUIDString;
    username: string;
    publicKey: string;
    displayPicture?: string | null;
    statusMessage?: string | null;
    createdAt: TimestampString;
  } & User_Key;
}

export interface ListAllChatsData {
  chats: ({
    id: UUIDString;
    name?: string | null;
    type: string;
    createdAt: TimestampString;
    description?: string | null;
  } & Chat_Key)[];
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

interface ListAllChatsRef {
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<ListAllChatsData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): QueryRef<ListAllChatsData, undefined>;
  operationName: string;
}
export const listAllChatsRef: ListAllChatsRef;

export function listAllChats(): QueryPromise<ListAllChatsData, undefined>;
export function listAllChats(dc: DataConnect): QueryPromise<ListAllChatsData, undefined>;

interface GetMyProfileRef {
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<GetMyProfileData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): QueryRef<GetMyProfileData, undefined>;
  operationName: string;
}
export const getMyProfileRef: GetMyProfileRef;

export function getMyProfile(): QueryPromise<GetMyProfileData, undefined>;
export function getMyProfile(dc: DataConnect): QueryPromise<GetMyProfileData, undefined>;

interface CreateChatMessageRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: CreateChatMessageVariables): MutationRef<CreateChatMessageData, CreateChatMessageVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: CreateChatMessageVariables): MutationRef<CreateChatMessageData, CreateChatMessageVariables>;
  operationName: string;
}
export const createChatMessageRef: CreateChatMessageRef;

export function createChatMessage(vars: CreateChatMessageVariables): MutationPromise<CreateChatMessageData, CreateChatMessageVariables>;
export function createChatMessage(dc: DataConnect, vars: CreateChatMessageVariables): MutationPromise<CreateChatMessageData, CreateChatMessageVariables>;

interface AddUserToChatRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddUserToChatVariables): MutationRef<AddUserToChatData, AddUserToChatVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: AddUserToChatVariables): MutationRef<AddUserToChatData, AddUserToChatVariables>;
  operationName: string;
}
export const addUserToChatRef: AddUserToChatRef;

export function addUserToChat(vars: AddUserToChatVariables): MutationPromise<AddUserToChatData, AddUserToChatVariables>;
export function addUserToChat(dc: DataConnect, vars: AddUserToChatVariables): MutationPromise<AddUserToChatData, AddUserToChatVariables>;

