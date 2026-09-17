document.addEventListener('DOMContentLoaded', () => {
    fetch('datos.json')
        .then(response => response.json())
        .then(data => {
            // Renderizar Presentación
            document.getElementById('presentacion-texto').innerHTML = data.presentacion;

            // Renderizar Unidades
            const container = document.getElementById('unidades-container');
            let html = '';

            data.unidades.forEach((unidad, index) => {
                const isOpen = index === 0 ? 'open' : '';
                html += `
                    <details class="unidad" ${isOpen}>
                        <summary>${unidad.titulo}</summary>
                        <div class="semanas-grid">
                `;

                unidad.semanas.forEach(semana => {
                    html += `
                        <div class="semana-card">
                            <h4>${semana.titulo}</h4>
                            <p>${semana.descripcion}</p>
                    `;
                    if(semana.actividades.length > 0) {
                        semana.actividades.forEach(act => {
                            html += `<a href="${act.archivo}" target="_blank" class="btn">${act.nombre}</a>`;
                        });
                    } else {
                        html += `<a href="#" class="btn" style="background-color: #ccc; cursor: not-allowed;">Próximamente</a>`;
                    }
                    html += `</div>`;
                });

                html += `
                        </div>
                    </details>
                `;
            });

            container.innerHTML = html;
        })
        .catch(error => {
            console.error('Error cargando los datos:', error);
            document.getElementById('presentacion-texto').innerText = 'Error al cargar los datos. Verifica que datos.json exista.';
        });
});
