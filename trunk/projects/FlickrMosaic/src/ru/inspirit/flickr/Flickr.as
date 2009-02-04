package ru.inspirit.flickr
{
	import com.adobe.webapis.flickr.events.FlickrResultEvent;
	import com.adobe.webapis.flickr.FlickrService;
	import com.adobe.webapis.flickr.PagedPhotoList;
	import com.adobe.webapis.flickr.Photo;
	import ru.inspirit.flickr.events.FlickrEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	/**
	* Flickr wraper class. I used it to simplify service calls.
	* 
	* @author Eugene Zatepyakin
	*/
	public class Flickr extends EventDispatcher
	{
		/**
		* This you FLICKR API key. Without it nothing will work! :)
		*/
		private const API_KEY:String = "YOUR FLICKR API KEY";
		
		public static const pool_colorfields:String = "31917163@N00";
		public static const pool_macro:String = "52241335207@N01";
		public static const pool_urban:String = "64262537@N00";
		public static const pool_digit:String = "54718308@N00";

		private var flickrService:FlickrService;
		private var _request:String;

		public function Flickr()
		{
			flickrService = new FlickrService( API_KEY );
			flickrService.addEventListener( FlickrResultEvent.GROUPS_POOLS_GET_PHOTOS, onFlickrResult );
			flickrService.addEventListener( FlickrResultEvent.PHOTOS_SEARCH, onFlickrResult );
			flickrService.addEventListener( FlickrResultEvent.PEOPLE_GET_PUBLIC_PHOTOS, onFlickrResult );
			flickrService.addEventListener( FlickrResultEvent.INTERESTINGNESS_GET_LIST, onFlickrResult );
			flickrService.addEventListener( FlickrResultEvent.PEOPLE_FIND_BY_USERNAME, onFlickrUserFind );
			flickrService.addEventListener( FlickrResultEvent.PEOPLE_GET_INFO, onFlickrResult );			
		}

		public function getPoolPhotos(pool_id:String = pool_colorfields, num:int = 100):void
		{
			_request = "GET_PHOTOS";
			flickrService.pools.getPhotos(pool_id, "", "", num);
		}
		
		public function getPhotos(user_id:String = "", tags:String = "", tag_mode:String = "any", num:int = 100):void
		{
			_request = "GET_PHOTOS";
			flickrService.photos.search( "", tags, tag_mode, "", null, null, null, null, -1, "", num );
		}
		
		public function getPublicPhotos(user_id:String, num:int = 100):void
		{
			_request = "GET_PHOTOS";
			flickrService.people.getPublicPhotos(user_id, "", num);
		}
		
		public function getUserByName(uname:String):void
		{
			_request = "FIND_USER";
			flickrService.people.findByUsername(uname);
		}
		
		public function getInterestingnessList(date:Date = null, extras:String = "", per_page:uint = 100, page:uint = 1):void
		{
			_request = "GET_PHOTOS";
			flickrService.interestingness.getList(date, extras, per_page, page);
		}
		
		private function onFlickrUserFind(event:FlickrResultEvent):void
		{
			if (event.success) {
				_request = "FIND_USER";
				flickrService.people.getInfo( event.data.user.nsid );
			} else {
				dispatchEvent(new FlickrEvent('FlickrError'));
			}
		}

		private function onFlickrResult(event:FlickrResultEvent):void
		{
			if (event.success) {
				dispatchEvent(new FlickrEvent(_request, event.data.photos, event.data.user));
			} else {
				dispatchEvent(new FlickrEvent('FlickrError'));
			}
		}

		public static function getFlickrPhotoUrl(ph:Photo, size:String = "square"):String
		{
			var sizes:Object = { "square":"_s", "thumbnail":"_t", "small":"_m", "medium":"", "large":"_b", "original":"_o" };

			return 'http://farm' +ph.farm + '.static.flickr.com/' + ph.server + '/' + ph.id + '_' + ph.secret + sizes[size] + '.jpg';
		}

	}

}