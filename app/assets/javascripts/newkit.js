function newkit() {
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            document.getElementById("newkit").innerHTML += this.responseText;
        }
    };
    xhttp.open("GET", "/kits/new", true);
    xhttp.send(new FormData());
}
