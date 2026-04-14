class Image;
    rand bit pixels[10][10];

    constraint c_color {
        foreach (pixels[i, j]) {
            pixels[i][j] dist {0:/20, 1:/80};
        }
    }
endclass : Image

program automatic test;
    initial begin
        Image img = new();
        int white_pxl = 0;
        int black_pxl = 0;
        assert(img.randomize());

        foreach (img.pixels[i,j]) begin
            $write("%s", img.pixels[i][j] ? "B" : "W");
            if (img.pixels[i][j]) black_pxl++;
            else white_pxl++;
            if (j == 9) $display;
        end

        $display("White=%0d, Black=%0d", white_pxl, black_pxl);
    end
endprogram : test