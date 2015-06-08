# ASSURF Bundle Manager #

![http://farm3.static.flickr.com/2547/4397923478_73b2e6a698_o.png](http://farm3.static.flickr.com/2547/4397923478_73b2e6a698_o.png)

This aim of the application is to help users quickly create packages for later use with [ASSURF](http://code.google.com/p/in-spirit/wiki/ASSURF). <br>It can produce compressed binary file or BASE64 encoded string that is easily can be parsed in your code.<br>
<br>
<h3>Features</h3>

<ul><li>Video and Image data input<br>
</li><li>Realtime match test with current list of references<br>
</li><li>Realtime reference elements and its points editing<br>
</li><li>Export/Import data as binary file or BASE64 string</li></ul>

<h3>Parsing output files</h3>

Output data is binary. After loading file and getting access to its <b>ByteArray</b> data you have to parse it:<br>
<pre><code>function parseData(data:ByteArray):void<br>
{<br>
    // binary file is compressed<br>
    data.uncompress();<br>
<br>
    // see if file also contains BitmapData bytes<br>
    var includeImages:Boolean = data.readBoolean();<br>
<br>
    // number of included references<br>
    var referenceCount:int = data.readInt();<br>
<br>
    var pointsCount:int = 0;<br>
<br>
    for( var i:int = 0; i &lt; referenceCount; ++i )<br>
    {<br>
	var pointsInReference = data.readInt();<br>
<br>
        if(includeImages)<br>
        {<br>
            // get included BitmapData width and height<br>
            var bitmap:BitmapData = new BitmapData(data.readInt(), data.readInt(), false, 0x00);<br>
            // next bytes are bitmap ByteArray<br>
            bitmap.setPixels(bitmap.rect, data);<br>
        }<br>
        pointsCount += pointsInReference;<br>
    }<br>
<br>
    // after getting all references info<br>
    // we get interest points data that is stored as single chunk<br>
    var pointsData:ByteArray = new ByteArray();<br>
    pointsData.endian = Endian.LITTLE_ENDIAN;<br>
<br>
    var pos:int = data.position;<br>
    var pointSize:int = 69 &lt;&lt; 3;<br>
<br>
    pointsData.writeBytes(data, pos, pointsCount * pointSize);<br>
<br>
    // if you want to get information of each point<br>
    // here is how data in single point presented<br>
    for( i = 0; i &lt; pointsCount; ++i )<br>
    {<br>
        pointsData.position = i * pointSize;<br>
<br>
        var iPoint:Object = {};<br>
<br>
        iPoint.x = pointsData.readDouble();<br>
        iPoint.y = pointsData.readDouble();<br>
        iPoint.scale = 2.5 * pointsData.readDouble();<br>
        iPoint.orientation = pointsData.readDouble();<br>
        iPoint.laplacian = pointsData.readDouble();<br>
<br>
        // other 64 &lt;&lt; 3 bytes chunk - point descriptors<br>
    }<br>
}<br>
</code></pre>

Data can be encoded in BASE64 to process it as string.<br>
If you get BASE64 encoded string you just need to decode it first and then the same parse operation.<br>
<br>
<h3>Download</h3>

<a href='http://in-spirit.googlecode.com/files/ASSURFBundleManager.zip'>ASSURF Bundle Manager</a>