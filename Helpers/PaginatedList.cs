using Microsoft.EntityFrameworkCore;

namespace Bookstore.Helpers
{
    public class PaginatedList<T> : List<T> //Inherits from List<T>
    {
        //private: encapsulate the props
        public int PageIndex { get; private set; }
        public int TotalPages { get; private set; }
        public int TotalCount { get; private set; }
        public int PageSize { get; private set; }
        //Constructor
        public PaginatedList(IEnumerable<T> items, int count, int pageIndex, int pageSize)
        {
            PageIndex = pageIndex;
            PageSize = pageSize;
            TotalCount = count; //Number of items
            TotalPages = (int)Math.Ceiling(count / (double)pageSize);
            this.AddRange(items); //Adds items to list
        }
        public bool HasPreviousPage => PageIndex > 1;
        public bool HasNextPage => PageIndex < TotalPages;

        public static async Task<PaginatedList<T>> CreateAsync(IQueryable<T> source, int pageIndex, int pageSize)
        //IQueryable: Represents a queryable collection of entities. This is used to avoid executing the query immediately
        {
            var count = await source.CountAsync(); //Executes SELECT COUNT(*) FROM source(Books)
            var items = await source.Skip((pageIndex - 1) * pageSize).Take(pageSize).ToListAsync(); //Executes SELECT * FROM source(Books) LIMIT pageSize OFFSET (pageIndex - 1) * pageSize
            return new PaginatedList<T>(items, count, pageIndex, pageSize);
        }
    }
}