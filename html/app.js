// Added: simple NUI controller for death screen & EKG
const overlay = document.getElementById('overlay');
const ekgState = document.getElementById('ekg-state');

function setState(state) {
    ekgState.classList.remove('unstable', 'flatline');
    let text = 'Stable';

    if (state === 'unstable') {
        text = 'Unstable';
        ekgState.classList.add('unstable');
    } else if (state === 'flatline') {
        text = 'Flatline';
        ekgState.classList.add('flatline');
    }

    ekgState.textContent = text;
}

function toggleOverlay(visible, state) {
    if (visible) {
        overlay.classList.remove('hidden');
    } else {
        overlay.classList.add('hidden');
    }
    if (state) {
        setState(state);
    }
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'toggle') {
        toggleOverlay(data.visible, data.status);
    }

    if (data.action === 'setState') {
        setState(data.status);
    }
});
