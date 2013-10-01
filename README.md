[angular-on-fire](http://angular-on-fire.tomchentw.com/)
================

An AngularJS library to provide access to Firebase.  
It gives one way sync of data and make changes using **ref** object like the original Firebase JS lib.  


Why
----------
The service `angularFire` provided by [angularFire](https://github.com/firebase/angularFire) is wierd. We have to provide $scope to the service.  
It makes me feel very **unconfortable**.  
But `angularFireCollection` only provides sync on collection, it doesn't provide one object sync.  

So I decide to write my own version.
