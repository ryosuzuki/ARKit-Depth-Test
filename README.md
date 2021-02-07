# ARKit-Depth-Test

- [x] Create git repo and init
- [x] Initial ARKit Test
- [x] Access depth dat
- [x] Mesh reconstruction demo
- [x] Send data via websocket
- [x] Receive data in node.js
- [x] Get mesh data
- [x] Send and receive mesh data
- [x] Reconstruct mesh data on the web
- [x] Use http post instead of websocket
- [x] Finish proof-of-concept prototype
- [ ] Check the position/trasform of mesh
- [ ] Label classification (wall, table, etc)


# How to use
What you need to do is
- clone the repo
- check your IP with "System Preferences > Network > Wi-Fi is connected to XXX and has the IP address 10.0.0.68."
- modify let url = "http://10.0.0.68:3000" to your IP in XCode at `ViewController.swift`
- build and deploy to iPhone 12 or iPad Pro
- `npm install` and `node server.js`
- open http://localhost:3000 in your browser

Then, I think you could probably run the app with iPhone 12 or iPad Pro + browser
