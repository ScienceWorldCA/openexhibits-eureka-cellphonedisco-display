/*
version 1.0

Methods:

1. setupTracking(obj:Object); // Set-up Data tracking settings

	obj.tracking_id = "UA-47473006-1";  // Google Analytics tracking ID
	obj.application_language = "en-us"; // Language 
	obj.screen_resolution = "550x400"; // Resolution
	obj.application_id = "http://testingapp.t1.ngx"; // App name and terminal ID
	
2. sendLoaded() // Sending application loaded event to analytics

3. sendScreen(screen_slug:String, screen_label:String) // Sends current screen to analytics
	screen_slug = "sample_slug"; // Lowercase label no spaces
	screen_label = "Sample Label"; // Label for screen
	
4. sendNonInteractionHit(xpos:Number, ypos:Number)
	xpos = 150; // x coordinate of the interaction (click or touch)
	ypos = 150; // y coordinate of the interaction (click or touch)
	
5. sendHotspotHit(hotspot_label:String, xpos:Number, ypos:Number)	
	hotspot_label = "Sample Label" // label for the hotspot
	xpos = 150; // x coordinate of the interaction (click or touch)
	ypos = 150; // y coordinate of the interaction (click or touch)
			
6. sendAttractBreak() //  Sends update to analytics when user interupts the attract screen 

7. sendAttractStart() // Sends update to analytics when attract screen starts
			
8. changeLanguage(newLanguage:String) // Change the language, no event sent
	newLanguage = "fr-ca" // Abbreviated language code (must be a real code supported by Google Analytics) 

9. sendQuit() //Sending application quick event to analytics


*/
package com.ngxinteractive.dts {
	
	import com.facebook.utils.GUID;

	
//	import flash.events.Event;
//	import flash.events.HTTPStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	public class DTS {
		
		
		private static const VERSION:String = "1";
		private static const URL:String = "http://www.google-analytics.com/collect";
		private static var urlVars:URLVariables;
		private static var statusTxt;
		public static var isOnline:Boolean = true;
		
		public function DTS() {
	
		}
		
		
		public static function setupTracking(setup:Object){
			
			
			if(setup.tracking_dev_enabled){
				setup.tracking_id = setup.tracking_dev_id;
			}
			urlVars = new URLVariables();
			
			urlVars['v'] = VERSION;
			urlVars['tid'] = setup.tracking_id;
			urlVars['cid'] = GUID.create();
			urlVars['ul'] = setup.application_language; 
			urlVars['vp'] = setup.screen_resolution; 
			urlVars['dr'] = setup.application_id; 
			
		}
		
		public static function slugify(string:String):String{
			const pattern1:RegExp = /[^w- ]/g; 
			const pattern2:RegExp = / +/g;
			var s:String = string;
			return s.replace(pattern1, "").replace(pattern2, "-").toLowerCase();
		}
		
		private static function leadingZero(num : Number) : String {
			if(num < 10) {
				return "0" + num;
			}
			return num.toString();
		}
		
		
		public static function sendLoaded(){
			clearEvent();
			urlVars['ea'] = "Application Loaded";
			urlVars['ec'] = "Application Event";
			urlVars['ev'] = 1;
			sendData('event');
		}
		
		public static function sendQuit(){
			clearEvent();
			urlVars['ea'] = "Application Quit";
			urlVars['ec'] = "Application Event";
			urlVars['ev'] = 1;
			sendData('event');
		}
		
		public static function sendScreen(screen_slug:String, screen_label:String):void {	
			urlVars['cid'] = GUID.create();
			urlVars['dp'] = screen_slug;
			urlVars['dt'] = screen_label;
			sendData('pageview');

		}
		
		public static function sendNonInteractionHit(xpos:Number, ypos:Number):void {
			urlVars['ni'] = true;
			urlVars['cd1'] = xpos;
			urlVars['cd2'] = ypos;
			urlVars['ea'] = "Non-Interactive Hit";
			urlVars['ec'] = "User Interaction";
			urlVars['ev'] = 1;
			sendData('event');
		}
		
		public static function sendAttractBreak(){
			clearEvent();
			urlVars['ea'] = "Attract Screen Break";
			urlVars['ec'] = "User Interaction";
			urlVars['ev'] = 1;
			sendData('event');
		}
			
		public static function sendAttractStart(){
			clearEvent();
			urlVars['ea'] = "Attract Screen Start";
			urlVars['ec'] = "Application Event";
			urlVars['ev'] = 1;
			sendData('event');
		}
			
		public static function changeLanguage(newLanguage:String){
			
			trace("changeLanguage: " + newLanguage);
			urlVars['ul'] = newLanguage;
		}
			
		public static function sendHotspotHit(hotspot_label:String, xpos:Number, ypos:Number):void {
			urlVars['cd1'] = xpos;
			urlVars['cd2'] = ypos;
			urlVars['cd3'] = hotspot_label;
			urlVars['ea'] = "Hotspot Hit";
			urlVars['ec'] = "User Interaction";
			urlVars['ev'] = 1;
			urlVars['t'] = 'event';
			sendData('event');
		}
		
		private static function clearEvent(){
			delete urlVars['ea'];
			delete urlVars['ni'];
			delete urlVars['cd1'];
			delete urlVars['cd2'];
			delete urlVars['cd3'];
			delete urlVars['ec'];
			delete urlVars['ev'];
		}
		
		public static function getStatus(){
			return statusTxt;	
		}
		
		private static function sendData(hitType):void {
			
			urlVars['cd4'] = leadingZero(new Date().getSeconds());
			
			urlVars['t'] = hitType;
			urlVars['z'] = String(new Date().getTime());
			
			trace(URL)
			var urlRequest : URLRequest = new URLRequest(URL);
			urlRequest.data = urlVars;
			urlRequest.method = URLRequestMethod.GET;
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			var txt = hitType;
			trace(hitType)
				txt += ('\n');
				txt += ('\n');
			for(var i in urlVars){
				trace(i + " - " + urlVars[i]);
				txt += (i + " - " + urlVars[i]);
					txt += ('\n');
			}
			trace('\n')
			txt += ('\n');
			statusTxt = txt;
			
			try {
				if(isOnline){
					urlLoader.load(urlRequest);
				}
				
			} catch (error:Error) {
				trace("Error! - Unable to load requested document");
			}
			
			if(hitType == "event"){
				clearEvent();
			}
			
		}
		

	}
	
}
