function historicalDataDisplay()
{
    if (document.getElementById('historical-data').checked)
    {
		$('#myModal').modal('show');
        document.getElementById('historical-data-display-checked').style.display = 'block';
        document.getElementById('historical-data-display-unchecked').style.display = 'none';
    } else {
        document.getElementById('historical-data-display-unchecked').style.display = 'block';
        document.getElementById('historical-data-display-checked').style.display = 'none';
    }
}