import $ from "jQuery";
import kmx_colors from "./kmx_colors";

function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

$(function() {
  setInterval(function() {
    const i = getRandomInt(kmx_colors.index.length);
    const name = kmx_colors.index[i];
    const color = kmx_colors[name];
    const x = getRandomInt(5) - 2;
    $("a").css("text-shadow", "0 0 0");
    $("a:hover").css("text-shadow", x + "px 0 0 " + color);
  }, 20);
});
