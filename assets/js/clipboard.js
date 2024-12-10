const setupClipboard = () => {
  window.addEventListener('phx:copy_to_clipboard', (e) => {
    const text = e.detail.text;
    const textarea = document.createElement('textarea');
    textarea.value = text;

    // Position off-screen but still selectable
    textarea.style.position = 'absolute';
    textarea.style.left = '-9999px';
    textarea.style.top = '0';
    textarea.setAttribute('readonly', ''); // Prevent mobile keyboard from showing

    document.body.appendChild(textarea);

    // For iOS
    const range = document.createRange();
    range.selectNodeContents(textarea);
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
    textarea.focus();
    textarea.setSelectionRange(0, textarea.value.length);

    let success = false;
    try {
      console.log('is secure context', document.isSecureContext);
      success = document.execCommand('copy');
      if (!success) {
        setTimeout(() => {
          navigator.clipboard.writeText(text).then(
            () => console.log('Text copied successfully'),
            (err) => console.error('Failed to copy text:', err)
          );
        }, 0);
      } else {
        console.log('Text copied successfully:', success);
        console.log('Copied text:', text);
      }
    } catch (err) {
      console.error('Failed to copy text:', err);
    }

    document.body.removeChild(textarea);
  });
};

export default setupClipboard;
