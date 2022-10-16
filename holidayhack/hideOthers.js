// ==UserScript==
// @name         Hide Others
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Hide other players in KingleCon
// @author       0xdf
// @match        https://kringlecon.com/
// @grant        none
// ==/UserScript==

window.setInterval(hideplayers, 1000);
function hideplayers(){
  document.querySelectorAll('.player').forEach(function (player) {
    if (!player.className.includes("me")) {
      player.style.visibility = 'hidden';
    }
  })
};
