package ru.inspirit.flickr.events
{
	import com.adobe.webapis.flickr.PagedPhotoList;
	import com.adobe.webapis.flickr.User;
	import flash.events.Event;

	/**
	* @author Eugene Zatepyakin
	*/
	public class FlickrEvent extends Event
	{

		public var photoList:PagedPhotoList;
		public var user:User;

		public function FlickrEvent( type:String, pl:PagedPhotoList = null, user:User = null ) {
			super( type );
			this.photoList = pl;
			this.user = user;
		}

	}

}