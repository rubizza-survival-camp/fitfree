function send_message(id) {
    var msg = document.getElementById("message").value;
    var xhttp = new XMLHttpRequest();
    let form_data = new FormData();
    form_data.append("message", msg);
    xhttp.onreadystatechange = function() {
        if (this.readyState === 4 && this.status === 200) {
            document.getElementById("container_msg").innerHTML += '<p style="float: right;">"Coach: "' + msg + '</p></br>';
        }
    };
    var url = `/clients/${id}/messages`;
    xhttp.open("POST", url, true);
    xhttp.send(form_data);
}

App.messages = App.cable.subscriptions.create('MessagesChannel', {
    received: function(data) {
        return document.getElementById("container_msg").innerHTML += this.renderMessage(data);
    },

    renderMessage: function(data) {
        return `<p><b>${data.user}:</b> ${data.message}</p>`;
    }
});
