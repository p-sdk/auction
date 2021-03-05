if (document.location.pathname == "/login") {
  const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  document.getElementById("user_timezone").value = tz
}
