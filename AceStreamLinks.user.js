// ==UserScript==
// @description   Replaces acestream://  with 127.0.0.1:6878/webui/player/
// @include       http://*
// @include       https://*
// ==/UserScript==
var url1,url2;
url1 = ['acestream://'];
url2 = ['127.0.0.1:6878/webui/player/'];
url3 = ['?autoplay=true'];
var a, links;
var tmp="a";
var p,q;
links = document.getElementsByTagName('a');
for (var i = 0; i < links.length; i++) {
    a = links[i];
    for(var j=0;j<url1.length; j++)
	{
	tmp = a.href+"" ;
	if(tmp.indexOf(url1[j]) != -1)
	{
	p=tmp.indexOf(url1[j]) ;
	q="http://";
	q = q + url2[j] + tmp.substring(p+url1[j].length,tmp.length)+ url3;
	a.href=q ;
	}
	}
    }
