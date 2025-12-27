# Common Instructions

Always review existing code and documentation before making changes.
Ensure that any new code adheres to existing coding standards and practices.
Do not create redundant code; reuse existing functions and classes where applicable. You can refactor existing code if necessary to improve maintainability.
Extend existing documentation to cover new features or changes.
Extend unit tests to cover new functionality and ensure all tests pass before finalizing changes.

# C64 HDN Cloud Server Application

Create python application that receives TCP data as commands from the C64 and responds back with data.
This application is supposed to run local PC or in serverless cloud.
C64 client requires C64 Ultimate with network target.
Create cloud.py that implements the server.

## Communication Protocol Client->Server

- 2 bytes: Magic $FE $FF | This indicates start of a command packet and distinguishes from other traffic
- 1 byte: Command ID | Identifies the command being sent
- n bytes: Command Data | Data specific to the command being sent

### Command IDs
- $01: C64 sending an immediate keypress, to be dispatched appropriately
- $02: C64 sending a string of PETSCII text input, terminated by $00

### Data Formats for particular Commands
- Command $01 (Immediate Keypress):
  - 1 byte: PETSCII code of the key pressed
  - 1 byte: Modifier flags (bit 0: Shift, bit 1: Ctrl, bit 2: Commodore key)
- Command $02 (Text Input String):
  - n bytes: PETSCII text string, ending with null character ($00)

## Communication Protocol Server->Client
- 2 bytes: Magic $FE $FF | This indicates start of a response packet
- 1 byte: Response Type | Following types are supported:
    - $01 PETSCII null terminated, 
    - $02 mix commands and screen codes, 
    - $03 mText format (see docs/mtext.md)
- n bytes: Response Data | Data specific to the response type

## PETSCII Conversion Rules

- Use PETSCII like native encoding inside the server. That means do not convert incoming PETSCII to ASCII/UTF-8 and vice versa.
- When the server needs to communicate to downstream services (like web APIs) that expect UTF-8, convert PETSCII to UTF-8 right before calling such API.
- For this conversion, use the petscii-ascii.md file containing mapping rules.
- Use PETSCII in responses back to C64 for all Response Types except $02 (mix commands and screen codes) where screen codes will be used.

When receiving UTF-8 data from downstream services, convert back to PETSCII using the inverse of the above rules.
Screen codes will be generated directly using binary literals in the code. No conversion needed.

### Reasons for conversion approach
- petscii > utf-8
  - for communicating with web APIs - must preserve the same meaning
  - so I can view/edit it in the cloud - must keep the same visual appearance
- utf-8 > petscii
  - for sending back to the C64


## PyTest

Create unit tests for cloud.py using pytest framework.
Write these tests before application development and work fixing all bugs until all tests pass.

## Test application for PC

Because the TCP traffic exchanged between C64 and the server is binary protocol, it is recommended to use a simple test application to verify the communication. Write a testing app that simulates the C64, able to send commands and receive responses.
Create test_client.py that implements this functionality.
The application will expect a user input

# Other Considerations


---

# Request Dispatcher

Create a dispatch object that will work for text inputs ($02: C64 sending a string of PETSCII text input). The dispatcher will identify type of request and route to the appropriate handler class. At the moment there will be only the following types:

| How to identify | Description | Handler Class |
|-----------------|-------------|---------------|
| starts by "I:"  | General chat requests to LLM Agent | ChatHandler |
| starts by "help" | Help requests | HelpHandler |
| starts by "?"   | Evaluate python expression | PythonEvalHandler |
| starts by "c:"  | requests to csdb.dk database | CSDBHandler |

Create python files for the classes above and implement basic functionality that can be extended later.

## ChatHandler

Use context7 langchain_oss_python_langchain to create a ChatHandler class that will process chat requests to an LLM agent.
The class will accept PETSCII text input, convert to UTF-8, send to the LLM, get the response, convert back to PETSCII and return.
Create following LLM tools:
- Web search tool using SerpAPI (use GOOGLE_CSE_ID env var for CSE ID)
Prepare string for system prompt.
Use MCP server like this:
```json
"mcp": {
  "servers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "<CONTEXT7_API_KEY>"
      }
    }
  }
}
```
The CONTEXT7_API_KEY is expected to be set in environment variables.

## HelpHandler

Create a HelpHandler class that will respond to help requests with a static PETSCII text response describing available commands.
If the "help" request contains additional text, use that as a search query to find relevant help topics from a predefined set. Use LLM agent with the Context7 MCP server to find the most relevant help topic and return that. Have a string for help system prompt.

## PythonEvalHandler

Create a PythonEvalHandler class that will evaluate python expressions sent from the C64. The class will accept PETSCII text input, convert to UTF-8, evaluate the expression using eval(), convert the result back to PETSCII and return.
For security reasons, restrict the available built-in functions and variables that can be accessed during evaluation.

## CSDBHandler

Create a CSDBHandler class that will process requests to csdb.dk database. The class will accept PETSCII text input, convert to UTF-8, send a request to csdb.dk API, get the response, convert back to PETSCII and return.
Use the requests library to make HTTP requests to the csdb.dk API.
"forum". This will return an XML with all the rooms in the forum. If you add the parameter roomid=<roomid> you will get all the topics in the specific room. Finally you can add the parameter topicid=<topicid> and get all the posts in the given topic.

### List of commands

Here are list of curl commands to get data from csdb.dk.


#### find -> find results

To find for a string (e.g., "Hondani") on csdb.dk and get the HTML result, use:

```sh
curl 'https://csdb.dk/search/?seinsel=all&search=Hondani'
```

This fetches the search results page for the given query. You can then parse the resulting HTML to extract information.

Lets add the "find" command. It will be a csdb command. syntax
c: find <whatever text>
It will make such a curl request to csdb
https://csdb.dk/search/?seinsel=all&search=bill&Go.x=8&Go.y=9

the output should be similar to this:
~~~
219   release matches:
123   DownloadBill Bailey (C64 Music)
3456  DownloadBill Bailey (C64 Music) by The Legionaire
67    DownloadBill the Cat (C64 Graphics)
89    DownloadBillard (C64 Crack) by EBST Software Ltd.
53    DownloadBilliards (C64 Crack) by Gods (G)
Show all 219 matching releases

1 group match:
573   The Billy Buckhead Crew (BBC) (United Kingdom)

40 scener matches:
Bill
Bill
Bill Best
Bill Pamier
Bill the Cat
Show all 40 matching sceners

1 BBS match:
765  Billionaire Boys Club (United States)

111 SID matches:
PlayBill by Jason Tyler (Neptune) (1993 The Second Ring)
PlayBill & Ted by Benjamin Dibbert (Nordischsound) (2023 Pixelbrei)
PlayBill Bailey by Paul Kleimeyer <?> (1983 Access Software Inc.)
PlayBill Bailey by Alan Beggerow (1990 Loadstar)
PlayBill Bass by JCH & Thomas Mogensen (DRAX) (1990 Vibrants)
Show all 111 matching SIDs
~~~

There will be max 5 items per section displayed. All of the items will be preceded by id of the item. I assume each id will have at most 5 digits plus one space character, hence align the disaply text of the items to 6th column. But if the id has more digits it is ok to print it misaligned.(more towards rigth)
The screen only has 40 columns, trim the lines to that width.

Before you make any changes inspect the existing code to avoid any duplicated code.

#### cd -> change directory
The csdb module will behave a bit like a file system.
##### Setting c: as default module
If user inputs "c:" without any further command, this backend will remember it so that when the user will input "find bill" the c: will will be assumed. In other words it will be interpreted the same like if the user inputs "c: find bill".

##### cd command
When user inputs command "cd" it will virtually change to that directory. For example the user session will go like this:
c:
cd group
find hondani
This example will assume csdb as module (with c:), next it will assume to treat groups only (with cd group) and the find hondani command will only list all found matches for hondani groups only. E.g. releases, sceners, BBS,... will be ignored.

###### cd into item detail
User can use cd command to get from listing into item detail. Example user session:
c:
cd group
find hondani
cd 901
This session will first find and list all groups matching Hondani. The actual Hondani group has id=901. When user used cd 901 it will show details of the Hondani group item. This is the like if the user will input: "c: group 901"

Notes:
1. add per-user session support. Use session id. The id will be a word (2bytes) integer. This id may be present in the requests later. If you do not get it in the request, simply assume $0000 which means it is a single session (single user).
2. Only assume csdb module if the user switched to the module by saying "c:".
3. Add support for pwd command that will be able to list the absolute path to the curren directory. Example pwd: c:/group/901 .

#### latest releases
#### latest forum posts

