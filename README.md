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
![<Image missing>](https://raw.githubusercontent.com/Dadido3/D3hex/master/Screenshots/Nodes_Simple.png)  
The "History" node is used to virtualize all operations made by the "Editor" node.
This allows undo and redo operations, until you finally press "save".
Without the "History" node, you would write directly into the "File".

## Language
The software is completely written in [PureBasic](http://www.purebasic.com), which produces lightweigth and native 32-bit and 64-bit applications.
It is planned to implement a plugin system, which allows to extend the available nodes.
In this case it would be possible to contribute in any language, which can compile c like shared libraries (.dll files).

## License
D3hex is release under the [GPL](./License/GNU GPL v2.0.txt).

## Screenshots
![<Image missing>](https://raw.githubusercontent.com/Dadido3/D3hex/master/Screenshots/4.png)
![<Image missing>](https://raw.githubusercontent.com/Dadido3/D3hex/master/Screenshots/1.png)
![<Image missing>](https://raw.githubusercontent.com/Dadido3/D3hex/master/Screenshots/3.png)
