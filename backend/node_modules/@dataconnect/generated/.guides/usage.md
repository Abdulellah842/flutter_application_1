# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { listAllChats, getMyProfile, createChatMessage, addUserToChat } from '@dataconnect/generated';


// Operation ListAllChats: 
const { data } = await ListAllChats(dataConnect);

// Operation GetMyProfile: 
const { data } = await GetMyProfile(dataConnect);

// Operation CreateChatMessage:  For variables, look at type CreateChatMessageVars in ../index.d.ts
const { data } = await CreateChatMessage(dataConnect, createChatMessageVars);

// Operation AddUserToChat:  For variables, look at type AddUserToChatVars in ../index.d.ts
const { data } = await AddUserToChat(dataConnect, addUserToChatVars);


```