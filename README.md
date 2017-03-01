D3hex
=====

D3hex is a fast and lightweight hex-editor.
To be more exact it grew to be a general binary file-editor and viewer, which includes a hex-editor among other things.
The goal of the software is to faciliate you with the tools to open, interpret, view and edit any file you wish.
One important element of this software is its node based approach.
This means that all functions of the software are available as single nodes, which can be combined to fulfil a specific task.

**Examples of nodes are:**
- Sources (A file, random data)
- Hex-editor
- Viewer (Graphs, image viewer)
- And many more

In a very simple case you just connect a source to the hex-editor node. This could look similar to this:
![<Image missing>](/Screenshots/Nodes_Simple.png)  
The "History" node is used to virtualize all operations made by the "Editor" node.
This allows undo and redo operations, until you finally press "save".
Without the "History" node, you would write directly into the "File".

## Features
- "Unlimited" datasize ( ~ 9.2 Exabytes)
- Max. filesize isn't limited to RAM
- Insert and delete operation
- Search and replace binary data, integers, floats, strings
- Open and edit virtual memory of processes
- Network terminal to communicate with any TCP or UDP based server
- Checksum and hashcode calculator
- Display data as graph or image
- Binary operation of two data sources (XOR, AND, OR)
- Data inspector (Integers, floats, strings)

## Future
- Node to compress and decompress zlib and/or gzip streams
- Node for statistics (Histogram, Entropy, Mean, ...)
- Node for math operations
  - Basic math
  - Crosscorrelation, Autocorrelation, Discrete Fourier Transformation, ...
- Disassembler (Capstone)
- Audioplayback
- Node to de- and encode common file formats (mp3, jpeg, png, ...)
- Physical or logical drives as data source
- Wavegenerator (Sine, Square, Triangle, ...)
- Node to compare binary data
- Text editor
- Clipboard as data source

## Language
The software is completely written in [PureBasic](http://www.purebasic.com), which produces lightweight and native 32-bit and 64-bit applications.
It is planned to implement a plugin system, which allows to extend the available nodes.
In this case it would be possible to contribute in any language, which can compile c like shared libraries (.dll files on Windows, .so files on Linux).
Soon it will be possible to create custom nodes with the Julia scripting language as well.

## License
D3hex is released under the [GPL](/LICENSE).

## Screenshots
![<Image missing>](/Screenshots/4.png)
![<Image missing>](/Screenshots/1.png)
![<Image missing>](/Screenshots/3.png)
