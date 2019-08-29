function onSignIn(googleUser) {
  var idToken = googleUser.getAuthResponse().id_token;
  var expires = new Date();
  expires.setDate(expires.getDate() + 30);
  document.cookie = "X-Flutter-IdToken=" + idToken +
      "; expires=" + expires.toUTCString() +
      "; path=/";
}

function onSignInFailure(error) {
  console.log(error);
  document.cookie = "X-Flutter-IdToken=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
}
