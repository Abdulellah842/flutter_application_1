# Generated TypeScript README
This README will guide you through the process of using the generated JavaScript SDK package for the connector `example`. It will also provide examples on how to use your generated SDK to call your Data Connect queries and mutations.

***NOTE:** This README is generated alongside the generated SDK. If you make changes to this file, they will be overwritten when the SDK is regenerated.*

# Table of Contents
- [**Overview**](#generated-javascript-readme)
- [**Accessing the connector**](#accessing-the-connector)
  - [*Connecting to the local Emulator*](#connecting-to-the-local-emulator)
- [**Queries**](#queries)
  - [*ListAllChats*](#listallchats)
  - [*GetMyProfile*](#getmyprofile)
- [**Mutations**](#mutations)
  - [*CreateChatMessage*](#createchatmessage)
  - [*AddUserToChat*](#addusertochat)

# Accessing the connector
A connector is a collection of Queries and Mutations. One SDK is generated for each connector - this SDK is generated for the connector `example`. You can find more information about connectors in the [Data Connect documentation](https://firebase.google.com/docs/data-connect#how-does).

You can use this generated SDK by importing from the package `@dataconnect/generated` as shown below. Both CommonJS and ESM imports are supported.

You can also follow the instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#set-client).

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
```

## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code.
You can also follow the emulator instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#instrument-clients).

```typescript
import { connectDataConnectEmulator, getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
connectDataConnectEmulator(dataConnect, 'localhost', 9399);
```

After it's initialized, you can call your Data Connect [queries](#queries) and [mutations](#mutations) from your generated SDK.

# Queries

There are two ways to execute a Data Connect Query using the generated Web SDK:
- Using a Query Reference function, which returns a `QueryRef`
  - The `QueryRef` can be used as an argument to `executeQuery()`, which will execute the Query and return a `QueryPromise`
- Using an action shortcut function, which returns a `QueryPromise`
  - Calling the action shortcut function will execute the Query and return a `QueryPromise`

The following is true for both the action shortcut function and the `QueryRef` function:
- The `QueryPromise` returned will resolve to the result of the Query once it has finished executing
- If the Query accepts arguments, both the action shortcut function and the `QueryRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Query
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each query. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-queries).

## ListAllChats
You can execute the `ListAllChats` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
listAllChats(): QueryPromise<ListAllChatsData, undefined>;

interface ListAllChatsRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<ListAllChatsData, undefined>;
}
export const listAllChatsRef: ListAllChatsRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
listAllChats(dc: DataConnect): QueryPromise<ListAllChatsData, undefined>;

interface ListAllChatsRef {
  ...
  (dc: DataConnect): QueryRef<ListAllChatsData, undefined>;
}
export const listAllChatsRef: ListAllChatsRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the listAllChatsRef:
```typescript
const name = listAllChatsRef.operationName;
console.log(name);
```

### Variables
The `ListAllChats` query has no variables.
### Return Type
Recall that executing the `ListAllChats` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `ListAllChatsData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface ListAllChatsData {
  chats: ({
    id: UUIDString;
    name?: string | null;
    type: string;
    createdAt: TimestampString;
    description?: string | null;
  } & Chat_Key)[];
}
```
### Using `ListAllChats`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, listAllChats } from '@dataconnect/generated';


// Call the `listAllChats()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await listAllChats();

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await listAllChats(dataConnect);

console.log(data.chats);

// Or, you can use the `Promise` API.
listAllChats().then((response) => {
  const data = response.data;
  console.log(data.chats);
});
```

### Using `ListAllChats`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, listAllChatsRef } from '@dataconnect/generated';


// Call the `listAllChatsRef()` function to get a reference to the query.
const ref = listAllChatsRef();

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = listAllChatsRef(dataConnect);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.chats);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.chats);
});
```

## GetMyProfile
You can execute the `GetMyProfile` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getMyProfile(): QueryPromise<GetMyProfileData, undefined>;

interface GetMyProfileRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<GetMyProfileData, undefined>;
}
export const getMyProfileRef: GetMyProfileRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getMyProfile(dc: DataConnect): QueryPromise<GetMyProfileData, undefined>;

interface GetMyProfileRef {
  ...
  (dc: DataConnect): QueryRef<GetMyProfileData, undefined>;
}
export const getMyProfileRef: GetMyProfileRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getMyProfileRef:
```typescript
const name = getMyProfileRef.operationName;
console.log(name);
```

### Variables
The `GetMyProfile` query has no variables.
### Return Type
Recall that executing the `GetMyProfile` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetMyProfileData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
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
```
### Using `GetMyProfile`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getMyProfile } from '@dataconnect/generated';


// Call the `getMyProfile()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getMyProfile();

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getMyProfile(dataConnect);

console.log(data.user);

// Or, you can use the `Promise` API.
getMyProfile().then((response) => {
  const data = response.data;
  console.log(data.user);
});
```

### Using `GetMyProfile`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getMyProfileRef } from '@dataconnect/generated';


// Call the `getMyProfileRef()` function to get a reference to the query.
const ref = getMyProfileRef();

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getMyProfileRef(dataConnect);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.user);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.user);
});
```

# Mutations

There are two ways to execute a Data Connect Mutation using the generated Web SDK:
- Using a Mutation Reference function, which returns a `MutationRef`
  - The `MutationRef` can be used as an argument to `executeMutation()`, which will execute the Mutation and return a `MutationPromise`
- Using an action shortcut function, which returns a `MutationPromise`
  - Calling the action shortcut function will execute the Mutation and return a `MutationPromise`

The following is true for both the action shortcut function and the `MutationRef` function:
- The `MutationPromise` returned will resolve to the result of the Mutation once it has finished executing
- If the Mutation accepts arguments, both the action shortcut function and the `MutationRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Mutation
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each mutation. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-mutations).

## CreateChatMessage
You can execute the `CreateChatMessage` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
createChatMessage(vars: CreateChatMessageVariables): MutationPromise<CreateChatMessageData, CreateChatMessageVariables>;

interface CreateChatMessageRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: CreateChatMessageVariables): MutationRef<CreateChatMessageData, CreateChatMessageVariables>;
}
export const createChatMessageRef: CreateChatMessageRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
createChatMessage(dc: DataConnect, vars: CreateChatMessageVariables): MutationPromise<CreateChatMessageData, CreateChatMessageVariables>;

interface CreateChatMessageRef {
  ...
  (dc: DataConnect, vars: CreateChatMessageVariables): MutationRef<CreateChatMessageData, CreateChatMessageVariables>;
}
export const createChatMessageRef: CreateChatMessageRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the createChatMessageRef:
```typescript
const name = createChatMessageRef.operationName;
console.log(name);
```

### Variables
The `CreateChatMessage` mutation requires an argument of type `CreateChatMessageVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface CreateChatMessageVariables {
  chatId: UUIDString;
  encryptedContent: string;
  messageType: string;
}
```
### Return Type
Recall that executing the `CreateChatMessage` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `CreateChatMessageData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface CreateChatMessageData {
  chatMessage_insert: ChatMessage_Key;
}
```
### Using `CreateChatMessage`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, createChatMessage, CreateChatMessageVariables } from '@dataconnect/generated';

// The `CreateChatMessage` mutation requires an argument of type `CreateChatMessageVariables`:
const createChatMessageVars: CreateChatMessageVariables = {
  chatId: ..., 
  encryptedContent: ..., 
  messageType: ..., 
};

// Call the `createChatMessage()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await createChatMessage(createChatMessageVars);
// Variables can be defined inline as well.
const { data } = await createChatMessage({ chatId: ..., encryptedContent: ..., messageType: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await createChatMessage(dataConnect, createChatMessageVars);

console.log(data.chatMessage_insert);

// Or, you can use the `Promise` API.
createChatMessage(createChatMessageVars).then((response) => {
  const data = response.data;
  console.log(data.chatMessage_insert);
});
```

### Using `CreateChatMessage`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, createChatMessageRef, CreateChatMessageVariables } from '@dataconnect/generated';

// The `CreateChatMessage` mutation requires an argument of type `CreateChatMessageVariables`:
const createChatMessageVars: CreateChatMessageVariables = {
  chatId: ..., 
  encryptedContent: ..., 
  messageType: ..., 
};

// Call the `createChatMessageRef()` function to get a reference to the mutation.
const ref = createChatMessageRef(createChatMessageVars);
// Variables can be defined inline as well.
const ref = createChatMessageRef({ chatId: ..., encryptedContent: ..., messageType: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = createChatMessageRef(dataConnect, createChatMessageVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.chatMessage_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.chatMessage_insert);
});
```

## AddUserToChat
You can execute the `AddUserToChat` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
addUserToChat(vars: AddUserToChatVariables): MutationPromise<AddUserToChatData, AddUserToChatVariables>;

interface AddUserToChatRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddUserToChatVariables): MutationRef<AddUserToChatData, AddUserToChatVariables>;
}
export const addUserToChatRef: AddUserToChatRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
addUserToChat(dc: DataConnect, vars: AddUserToChatVariables): MutationPromise<AddUserToChatData, AddUserToChatVariables>;

interface AddUserToChatRef {
  ...
  (dc: DataConnect, vars: AddUserToChatVariables): MutationRef<AddUserToChatData, AddUserToChatVariables>;
}
export const addUserToChatRef: AddUserToChatRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the addUserToChatRef:
```typescript
const name = addUserToChatRef.operationName;
console.log(name);
```

### Variables
The `AddUserToChat` mutation requires an argument of type `AddUserToChatVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface AddUserToChatVariables {
  chatId: UUIDString;
  userId: UUIDString;
  role?: string | null;
}
```
### Return Type
Recall that executing the `AddUserToChat` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `AddUserToChatData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface AddUserToChatData {
  chatParticipant_insert: ChatParticipant_Key;
}
```
### Using `AddUserToChat`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, addUserToChat, AddUserToChatVariables } from '@dataconnect/generated';

// The `AddUserToChat` mutation requires an argument of type `AddUserToChatVariables`:
const addUserToChatVars: AddUserToChatVariables = {
  chatId: ..., 
  userId: ..., 
  role: ..., // optional
};

// Call the `addUserToChat()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await addUserToChat(addUserToChatVars);
// Variables can be defined inline as well.
const { data } = await addUserToChat({ chatId: ..., userId: ..., role: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await addUserToChat(dataConnect, addUserToChatVars);

console.log(data.chatParticipant_insert);

// Or, you can use the `Promise` API.
addUserToChat(addUserToChatVars).then((response) => {
  const data = response.data;
  console.log(data.chatParticipant_insert);
});
```

### Using `AddUserToChat`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, addUserToChatRef, AddUserToChatVariables } from '@dataconnect/generated';

// The `AddUserToChat` mutation requires an argument of type `AddUserToChatVariables`:
const addUserToChatVars: AddUserToChatVariables = {
  chatId: ..., 
  userId: ..., 
  role: ..., // optional
};

// Call the `addUserToChatRef()` function to get a reference to the mutation.
const ref = addUserToChatRef(addUserToChatVars);
// Variables can be defined inline as well.
const ref = addUserToChatRef({ chatId: ..., userId: ..., role: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = addUserToChatRef(dataConnect, addUserToChatVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.chatParticipant_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.chatParticipant_insert);
});
```

