$(document).ready ->
  $("#new_doge").on "ajax:success", (e, data, status, xhr) ->
    console.log('test' + data.image)
    $("#doge_image").slideUp 500, ->
      $("#doge_image").attr("src", "data:image/png;base64," + data.image)
      $("#doge_image").slideDown(500)