const REPO_OWNER = 'mirlenespejocosme-commits';
const REPO_NAME = 'BasedeDatos2';

let githubToken = localStorage.getItem('github_token');
let portfolioData = null;
let datosJsonSha = null;

if (!githubToken) {
    alert('No estás autenticado.');
    window.location.href = 'index.html';
}

document.addEventListener('DOMContentLoaded', loadData);

function logout() {
    localStorage.removeItem('github_token');
    window.location.href = 'index.html';
}

async function fetchFromGithub(path) {
    const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}`, {
        headers: {
            'Authorization': `token ${githubToken}`,
            'Accept': 'application/vnd.github.v3+json'
        }
    });
    if (!res.ok) throw new Error('Error al conectar con GitHub. Verifica tu Token.');
    return res.json();
}

async function loadData() {
    try {
        const fileData = await fetchFromGithub('datos.json');
        datosJsonSha = fileData.sha;
        const decodedContent = decodeURIComponent(escape(atob(fileData.content)));
        portfolioData = JSON.parse(decodedContent);
        renderAdmin();
    } catch (e) {
        alert(e.message);
        console.error(e);
    }
}

function renderAdmin() {
    document.getElementById('presentacion-texto').innerText = portfolioData.presentacion;

    const container = document.getElementById('unidades-container');
    let html = '';

    portfolioData.unidades.forEach((unidad, uIdx) => {
        html += `
            <details class="unidad" open>
                <summary>
                    <span contenteditable="true" onclick="event.preventDefault()" onblur="updateUnidadTitulo(${uIdx}, this.innerText)" style="border:1px dashed #fff; padding:2px; margin-right: 10px;">${unidad.titulo}</span>
                </summary>
                <div class="semanas-grid">
        `;

        unidad.semanas.forEach((semana, sIdx) => {
            html += `
                <div class="semana-card">
                    <h4 contenteditable="true" onblur="updateSemanaTitulo(${uIdx}, ${sIdx}, this.innerText)" style="border:1px dashed #ccc; padding:2px;">${semana.titulo}</h4>
                    <p contenteditable="true" onblur="updateDesc(${uIdx}, ${sIdx}, this.innerText)" style="border:1px dashed #ccc; padding:5px;">${semana.descripcion}</p>
            `;
            
            if (!semana.carpetas) semana.carpetas = [];

            semana.carpetas.forEach((carpeta, cIdx) => {
                html += `
                    <div style="margin-top: 10px; border: 1px solid #ddd; padding: 10px; border-radius: 6px; background-color: #f4f6f9; text-align: left;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                            <h5 contenteditable="true" onblur="updateCarpetaTitulo(${uIdx}, ${sIdx}, ${cIdx}, this.innerText)" style="margin: 0; color: #333; border:1px dashed #ccc; padding:2px;">📁 ${carpeta.nombre}</h5>
                            <button onclick="borrarCarpeta(${uIdx}, ${sIdx}, ${cIdx})" class="btn-sm btn-danger" style="padding:2px 5px;" title="Eliminar Carpeta">X</button>
                        </div>
                `;

                if (!carpeta.actividades) carpeta.actividades = [];
                
                carpeta.actividades.forEach((act, aIdx) => {
                    html += `
                        <div style="margin-top:5px; padding:5px; background:#fff; border:1px solid #eee; border-radius:4px; font-size:0.9rem;">
                            <a href="${act.archivo}" target="_blank">${act.nombre}</a>
                            <button onclick="borrarActividad(${uIdx}, ${sIdx}, ${cIdx}, ${aIdx})" class="btn-sm btn-danger" style="float:right; padding: 2px 5px;">X</button>
                        </div>
                    `;
                });

                html += `
                        <div style="margin-top: 10px; text-align:center;">
                            <button onclick="openActividadModal(${uIdx}, ${sIdx}, ${cIdx})" class="btn btn-sm btn-info">➕ Subir Trabajo</button>
                        </div>
                    </div>
                `;
            });

            html += `
                    <div class="admin-controls">
                        <button onclick="openCarpetaModal(${uIdx}, ${sIdx})" class="btn btn-sm">➕ Nueva Carpeta</button>
                    </div>
                </div>
            `;
        });

        html += `
                </div>
            </details>
        `;
    });

    container.innerHTML = html;
}

function updateUnidadTitulo(uIdx, newText) {
    portfolioData.unidades[uIdx].titulo = newText;
}

function updateSemanaTitulo(uIdx, sIdx, newText) {
    portfolioData.unidades[uIdx].semanas[sIdx].titulo = newText;
}

function updateCarpetaTitulo(uIdx, sIdx, cIdx, newText) {
    const cleanText = newText.replace('📁', '').trim();
    portfolioData.unidades[uIdx].semanas[sIdx].carpetas[cIdx].nombre = cleanText;
}

function updateDesc(uIdx, sIdx, newText) {
    portfolioData.unidades[uIdx].semanas[sIdx].descripcion = newText;
}

function editarPresentacion() {
    const newText = prompt("Edita tu presentación:", portfolioData.presentacion);
    if (newText !== null) {
        portfolioData.presentacion = newText;
        renderAdmin();
    }
}

function borrarCarpeta(uIdx, sIdx, cIdx) {
    if (confirm('¿Seguro que quieres borrar toda la carpeta y su contenido?')) {
        portfolioData.unidades[uIdx].semanas[sIdx].carpetas.splice(cIdx, 1);
        renderAdmin();
    }
}

function borrarActividad(uIdx, sIdx, cIdx, aIdx) {
    if (confirm('¿Seguro que quieres borrar este trabajo?')) {
        portfolioData.unidades[uIdx].semanas[sIdx].carpetas[cIdx].actividades.splice(aIdx, 1);
        renderAdmin();
    }
}

function openCarpetaModal(uIdx, sIdx) {
    document.getElementById('modal-carpeta-uIdx').value = uIdx;
    document.getElementById('modal-carpeta-sIdx').value = sIdx;
    document.getElementById('carpeta-nombre').value = '';
    document.getElementById('modal-carpeta').style.display = 'block';
}

function guardarCarpeta() {
    const uIdx = document.getElementById('modal-carpeta-uIdx').value;
    const sIdx = document.getElementById('modal-carpeta-sIdx').value;
    const nombre = document.getElementById('carpeta-nombre').value;

    if (!nombre) {
        alert('Ponle un nombre a la carpeta');
        return;
    }

    if (!portfolioData.unidades[uIdx].semanas[sIdx].carpetas) {
        portfolioData.unidades[uIdx].semanas[sIdx].carpetas = [];
    }

    portfolioData.unidades[uIdx].semanas[sIdx].carpetas.push({
        nombre: nombre,
        actividades: []
    });

    closeModal('modal-carpeta');
    renderAdmin();
}

function openActividadModal(uIdx, sIdx, cIdx) {
    document.getElementById('modal-unidad-idx').value = uIdx;
    document.getElementById('modal-semana-idx').value = sIdx;
    document.getElementById('modal-carpeta-idx').value = cIdx;
    document.getElementById('act-nombre').value = '';
    document.getElementById('act-file').value = '';
    document.getElementById('modal-actividad').style.display = 'block';
}

function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}

async function guardarActividad() {
    const uIdx = document.getElementById('modal-unidad-idx').value;
    const sIdx = document.getElementById('modal-semana-idx').value;
    const cIdx = document.getElementById('modal-carpeta-idx').value;
    const nombre = document.getElementById('act-nombre').value;
    const fileInput = document.getElementById('act-file');

    if (!nombre) {
        alert('Ponle un nombre al trabajo');
        return;
    }

    let fileName = "#";

    if (fileInput.files.length > 0) {
        const file = fileInput.files[0];
        // Clean filename
        fileName = file.name.replace(/\s+/g, '_');
        
        showLoading(true);
        try {
            const base64Data = await fileToBase64(file);
            await uploadFileToGithub(fileName, base64Data.split(',')[1]);
        } catch (e) {
            alert('Error subiendo el archivo: ' + e.message);
            showLoading(false);
            return;
        }
    } else {
        fileName = prompt("Si no subes archivo, ingresa la URL o deja #", "#");
    }

    portfolioData.unidades[uIdx].semanas[sIdx].carpetas[cIdx].actividades.push({
        nombre: nombre,
        archivo: fileName
    });

    closeModal('modal-actividad');
    renderAdmin();
    
    if (fileInput.files.length > 0) {
        // Automatically save json after uploading a file
        await saveToGithub();
        showLoading(false);
        alert('Archivo subido y base de datos actualizada.');
    }
}

function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => resolve(reader.result);
        reader.onerror = error => reject(error);
    });
}

async function uploadFileToGithub(fileName, base64Content) {
    const body = {
        message: `Admin: Subiendo archivo ${fileName}`,
        content: base64Content
    };

    try {
        const existing = await fetchFromGithub(fileName);
        body.sha = existing.sha;
    } catch(e) {
        // Doesn't exist, fine
    }

    const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${fileName}`, {
        method: 'PUT',
        headers: {
            'Authorization': `token ${githubToken}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    });

    if (!res.ok) throw new Error('Falló la subida a GitHub');
}

async function saveToGithub() {
    showLoading(true);
    try {
        const jsonString = JSON.stringify(portfolioData, null, 2);
        const base64Content = btoa(unescape(encodeURIComponent(jsonString)));

        const body = {
            message: 'Admin: Actualizando estructura del portafolio',
            content: base64Content,
            sha: datosJsonSha
        };

        const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/datos.json`, {
            method: 'PUT',
            headers: {
                'Authorization': `token ${githubToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        if (!res.ok) throw new Error('Error al guardar datos.json');
        
        const responseData = await res.json();
        datosJsonSha = responseData.content.sha; // Update SHA
        
        alert('¡Cambios guardados exitosamente en GitHub!');
    } catch(e) {
        alert(e.message);
    }
    showLoading(false);
}

function showLoading(show) {
    document.getElementById('loading-overlay').style.display = show ? 'block' : 'none';
}
