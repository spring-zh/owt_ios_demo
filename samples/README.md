# Intel® Collaboration Suite for WebRTC iOS Samples README


## Conference Sample

Conference sample sends HTTP post requests to basic example server to fetch token, then connect to Conference Server. After connecting to Conference Server, it is able to publish stream captured from a camera or subscribe streams from remote sides. By default, the sample subscribes mixed stream from conference server.

### TLS/SSL

- Basic example server also accepts HTTPS requests, so you can modify sample code to fetch token with HTTPS requests.
- The ```sioclient_tls.a``` provided in release package will verify server's certificate, so do remember to replace conference server's certificate(```<conference server folder>/cert/certificate.pfx```) with a trusted one. Or you can disable ssl by changing ```config.erizoController.ssl```(in ```<conference server folder>/etc/woogeen_config.js```) to ```false``` and replace ```sioclient_tls.a``` with ```sioclient.a```.
- As ATS(Application Transport Security) is required by the end of 2016, please enable TLS/SSL in production environments, and remove "NSAllowsArbitraryLoads" from samples' info.plist before submitting for App Store review.

## P2P Sample

P2P sample connects to PeerServer and can start a session with other client connected to PeerServer with Intel CS for WebRTC client SDK.


## Intel CS for WebRTC Websites
[Home Page](http://webrtc.intel.com/)

[Forum](https://software.intel.com/en-us/forums/intel-collaboration-suite-for-webrtc)
