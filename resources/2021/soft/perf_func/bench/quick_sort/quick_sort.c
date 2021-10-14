int partition(int *a, int p, int q)
{
	int pivot = a[p];
	int i = p, j = q;
	while (i < j)
	{
		while (i < j && a[j] > pivot)
			j--;
		a[i] = a[j];

		while (i < j && a[i] <= pivot)
			i++;
		a[j] = a[i];
	}

	a[i] = pivot;
	return i;
}

int quick_result[1000];
int *quick_sort(int *a, int N)
{
	int i;
	for (i = 0; i < N; i++)
	{
		quick_result[i] = a[i];
	}
	_quick_sort(quick_result, 0, N - 1);
	return quick_result;
}
void _quick_sort(int *a, int p, int q)
{
	if (p >= q)
		return;
	int m = partition(a, p, q);
	_quick_sort(a, p, m - 1);
	_quick_sort(a, m + 1, q);
}
