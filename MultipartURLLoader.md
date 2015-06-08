# Multipart URLLoader Class #

During one of the projects I faced a problem to upload multipart/form-data to server using Flash. I need to do it using Actionscript only. The idea was to send to server an image generated in flash and several variables but all this data had to be POST.
I found several projects that were using Flash Socket to send multipart requests to server but the problem was that sockets required custom server configuration to work. As you understand we cant ask remote service to reconfigure their system only because we need it.
So the only way was to build your own custom URLLoader class (not socket) to send multipart form data.
**Unfortunately there is a problem getting progress event. We cant show any progress during sending data to server because flash doesn't support it. (the same problem with sockets)**

## How To ##
**[Complete source code and test usage example with small PHP script available in my repository](http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/MultipartURLLoader)**

## Change Log ##
  * 2009.03.05 - **v1.3**
    * Added Async property. Now you can prepare data asynchronous before sending it.
    * It will prevent flash player from freezing while constructing request data.
    * You can specify the amount of bytes to write per iteration through BLOCK\_SIZE static property.
    * Added events for asynchronous method.
    * Added dataFormat property for returned server data.
    * Removed 'Cache-Control' from headers and added custom requestHeaders array property.
    * Added getter for the URLLoader class used to send data.
  * 2009.02.09 - **v1.2.1**
    * Changed 'useWeakReference' to false (thanx to zlatko). It appears that on some servers setting 'useWeakReference' to true completely disables this event
  * 2009.01.20 - **v1.2**
    * Added clearVariables and clearFiles methods
    * Small code refactoring
    * Public methods documentation
  * 2009.01.19 - **v1.1**
    * Added options for MIME-types (default is application/octet-stream).
  * 2009.01.15 - **v1.0**
    * Initial release.