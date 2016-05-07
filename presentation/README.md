#Presentation Instructions 

[Read this for the instructions](http://halyph.com/blog/2015/05/18/golang-presentation-tool/)

Basically 

1. Install Go 
2. [Set your $GOPATH](https://golang.org/doc/code.html#GOPATH), the directory to where you want to install go packages
3. `go get golang.org/x/tools/cmd/present`


The `.slide` file format is simple, and can be found here: https://godoc.org/golang.org/x/tools/present

In order to run a code snippet in the presentation, we'll need to have a custom header in each .scm file that we want to run. Mine looks like: 

```bash
#!/bin/bash
source /Users/gmgilmore/.bash_profile
mit-scheme-script /Users/gmgilmore/dev/todo-lisp/presentation/hello.scm
exit
;;START OMIT
(display "hello, world!")
;;END OMIT                                                                                                          
```


`#!/bin/bash` - Path to your shell 

`source ...` - Path to your bash config (more on that later)

`mit-scheme-script ...` - put the full path to the code snippet here 

`;;START OMIT...;;END OMIT` - only the lines in between these pieces of code will appear in the slide


In your bash config, have the following definitions: 

```bash
mit-scheme() {
	#path to your mit-scheme command 
    /Applications/MIT-Scheme.app/Contents/Resources/mit-scheme
}

mit-scheme-script(){
    for program in $@
    do
	# skip the first 4 lines of the script
	tail -n+5 $program | mit-scheme 
    done
}
```
I know that this is a super janky way to do this, but it works (and is pretty cool). 

In order to run the presentation, simply navigate to the directory where the presentation is contained and run `present`. It'll give you a web address to visit. Paste it into your browser and you're good to go. 
