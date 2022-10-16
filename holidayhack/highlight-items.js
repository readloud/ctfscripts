// ==UserScript==
// @name         Holiday Hack Highlight items
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       0xdf
// @match        https://2020.kringlecon.com/
// @grant        none
// @run-at       document-idle
// ==/UserScript==
window.setInterval(highlight_items, 2000);
function highlight_items() {
    document.querySelectorAll('.item-clicker').forEach(function (item) {
      item.style.backgroundColor = "rgba(255,192,203,0.5)";
      item.style.border = "2px red solid";
      item.style.borderRadius = "100px";
  })
};
