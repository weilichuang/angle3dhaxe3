haxe run doc.hxml
cd/d ..
haxelib run dox -i doc/documentation.xml -in com -in org -ex post --title Angle3D -o doc
cd/d doc
del /F documentation.xml