// Función para enviar el testigo con descripción
function sendTestigo() {
    const descripcion = document.getElementById('descripcion').value || "Sin descripción"; // Valor predeterminado
    fetch(`https://${GetParentResourceName()}/sendTestigo`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ descripcion: descripcion }) // Enviar la descripción al servidor
    }).then(() => closeUI());
}

// Función para cerrar el menú UI y notificar al servidor
function closeUI() {
    document.body.style.display = 'none';  // Ocultar la interfaz
    fetch(`https://${GetParentResourceName()}/closeUI`);  // Notificar al servidor que se cerró la UI
}

// Evento para abrir/cerrar la interfaz
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'open') {
        document.body.style.display = 'flex';  // Mostrar la interfaz
    } else if (data.action === 'close') {
        closeUI();  // Cerrar la interfaz
    }
});

// Evento para cerrar la interfaz con la tecla Escape
document.addEventListener('keyup', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});
