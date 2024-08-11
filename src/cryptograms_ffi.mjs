export function moveToNextEmptyField(nextFieldID) {
  const inputs = Array.from(document
    .querySelectorAll('input'))
    .filter((input) => {
      return parseInt(input.id) >= parseInt(nextFieldID)
    });

  for (let i = 0; i < inputs.length; i++) {
    if (inputs[i].value === '') {
      inputs[i].focus();
      return parseInt(inputs[i].id);
    }
  }
}

export function moveToNextField(nextFieldID) {
  const inputs = Array.from(document
    .querySelectorAll('input'))
    .filter((input) => {
      return parseInt(input.id) >= parseInt(nextFieldID)
    });

  inputs[0].focus()
  return parseInt(inputs[0].id)
}

export function moveToPreviousField(currentFieldID) {
  const inputs = Array.from(document
    .querySelectorAll('input'))
    .filter((input) => {
      return parseInt(input.id) < parseInt(currentFieldID)
    })
    .reverse();

  inputs[0].focus()
  return parseInt(inputs[0].id)
}
