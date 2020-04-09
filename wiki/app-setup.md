# App Setup

asdsadsadsa

## Franz

Franz does not work with gmail and two factor auth unless the user agent is changed. To do this add 
```
module.exports = Franz => class Hangouts extends Franz { overrideUserAgent() { return "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.10136"; } };
```
as the final line in the `gmail/index.js` file in franz.

* In linux this is at `~/.config/Franz/recipes/gmail/index.js`
* In MacOS this is at `~/Library/ApplicationSupport/Franz/recipes/gmail/index.js`
