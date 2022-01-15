import $ from "jquery"

$(function () {
  $("select.tree").change(function () {
    document.location = this.value;
  });
});
